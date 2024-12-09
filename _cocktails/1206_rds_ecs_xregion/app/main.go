package main

import (
	"database/sql"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	_ "github.com/go-sql-driver/mysql"
)

func main() {
	db, err := sql.Open("mysql", os.Args[1])
	if err != nil {
		log.Panicln(err)
	}

	db.SetConnMaxLifetime(time.Minute * 3)
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(10)

	r := gin.Default()
	r.GET("/app", func(ctx *gin.Context) {
		ctx.JSON(http.StatusOK, gin.H{
			"connect_error": db.Ping(),
		})
	})

	r.Run("0.0.0.0:8080")
}
