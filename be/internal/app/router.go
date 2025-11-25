package app

import (
	"log"
	"time"
	"yourapp/internal/config"
	"yourapp/internal/model"
	"yourapp/internal/repository"
	"yourapp/internal/service"
	"yourapp/internal/util"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func NewRouter(cfg *config.Config) *gin.Engine {
	// Set Gin mode
	if cfg.ServerPort == "5000" {
		gin.SetMode(gin.DebugMode)
	} else {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	// CORS middleware
	r.Use(corsMiddleware(cfg.ClientURL))

	// Initialize database
	db, err := initDB(cfg)
	if err != nil {
		panic("Failed to connect to database: " + err.Error())
	}

	// Auto migrate
	if err := db.AutoMigrate(&model.User{}, &model.Room{}, &model.RoomParticipant{}); err != nil {
		panic("Failed to migrate database: " + err.Error())
	}

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	roomRepo := repository.NewRoomRepository(db)

	// Initialize RabbitMQ with retry logic
	rabbitMQ := initRabbitMQWithRetry(cfg)

	// Initialize email service
	emailService := service.NewEmailService(cfg)

	// Initialize email worker if RabbitMQ is available
	var emailWorker *service.EmailWorker
	if rabbitMQ != nil {
		emailWorker = service.NewEmailWorker(emailService, rabbitMQ)
		if err := emailWorker.Start(); err != nil {
			log.Printf("Warning: Failed to start email worker: %v", err)
		} else {
			log.Println("Email worker started successfully")
		}
	} else {
		log.Println("Email worker not started - RabbitMQ connection failed. Will retry on first email send.")
		// Note: RabbitMQ will be reconnected automatically when email is sent via ensureRabbitMQ()
		// No need for continuous polling - lazy reconnection is more efficient
	}

	// Initialize services
	authService := service.NewAuthServiceWithConfig(userRepo, cfg.JWTSecret, rabbitMQ, cfg)
	roomService := service.NewRoomService(roomRepo, userRepo, cfg)

	// Initialize handlers
	authHandler := NewAuthHandler(authService, cfg.JWTSecret)
	roomHandler := NewRoomHandler(roomService)

	// API routes
	api := r.Group("/api/v1")
	{
		// Auth routes
		auth := api.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/verify-otp", authHandler.VerifyOTP)
			auth.POST("/resend-otp", authHandler.ResendOTP)
			auth.POST("/google-oauth", authHandler.GoogleOAuth)
			auth.POST("/refresh-token", authHandler.RefreshToken)
			auth.POST("/forgot-password", authHandler.RequestResetPassword)
			auth.POST("/verify-reset-password", authHandler.VerifyResetPassword)
			auth.POST("/reset-password", authHandler.ResetPassword)
			auth.POST("/verify-email", authHandler.VerifyEmail)

			// Protected routes
			auth.GET("/me", authHandler.AuthMiddleware(), authHandler.GetMe)
		}

		// Room routes
		rooms := api.Group("/rooms")
		{
			// Public routes
			rooms.GET("", roomHandler.GetRooms)
			rooms.GET("/:id", roomHandler.GetRoom)

			// Protected routes
			rooms.POST("", authHandler.AuthMiddleware(), roomHandler.CreateRoom)
			rooms.GET("/my", authHandler.AuthMiddleware(), roomHandler.GetMyRooms)
			rooms.POST("/:id/join", authHandler.AuthMiddleware(), roomHandler.JoinRoom)
			rooms.POST("/:id/leave", authHandler.AuthMiddleware(), roomHandler.LeaveRoom)
			rooms.DELETE("/:id", authHandler.AuthMiddleware(), roomHandler.DeleteRoom)
		}
	}

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	return r
}

func initDB(cfg *config.Config) (*gorm.DB, error) {
	dsn := cfg.DatabaseURL
	if dsn == "" {
		dsn = "host=" + cfg.PostgresHost +
			" port=" + cfg.PostgresPort +
			" user=" + cfg.PostgresUser +
			" password=" + cfg.PostgresPassword +
			" dbname=" + cfg.PostgresDB +
			" sslmode=" + cfg.PostgresSSLMode
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	return db, nil
}

// initRabbitMQWithRetry attempts to connect to RabbitMQ with exponential backoff retry
func initRabbitMQWithRetry(cfg *config.Config) *util.RabbitMQClient {
	maxRetries := 10
	initialDelay := 2 * time.Second
	maxDelay := 30 * time.Second

	for attempt := 1; attempt <= maxRetries; attempt++ {
		rabbitMQ, err := util.NewRabbitMQClient(cfg)
		if err == nil {
			log.Printf("RabbitMQ connected successfully on attempt %d", attempt)
			return rabbitMQ
		}

		if attempt < maxRetries {
			// Calculate delay with exponential backoff
			delay := initialDelay * time.Duration(1<<uint(attempt-1))
			if delay > maxDelay {
				delay = maxDelay
			}

			log.Printf("Failed to connect to RabbitMQ (attempt %d/%d): %v. Retrying in %v...", attempt, maxRetries, err, delay)
			time.Sleep(delay)
		} else {
			log.Printf("Warning: Failed to connect to RabbitMQ after %d attempts: %v. Email sending will be disabled.", maxRetries, err)
			log.Println("Note: RabbitMQ will be retried automatically when email is sent (if connection is restored)")
		}
	}

	return nil
}

func corsMiddleware(clientURL string) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", clientURL)
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
