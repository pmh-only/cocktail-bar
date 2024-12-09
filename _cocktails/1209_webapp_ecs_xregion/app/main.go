package main

import (
	"database/sql"
	"io"
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
		err := db.Ping()

		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
			})

			return
		}

		resp, err := http.Get(os.Getenv("ECS_CONTAINER_METADATA_URI_V4") + "/task")
		defer resp.Body.Close()

		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
			})

			return
		}

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
			})

			return
		}

		ctx.JSON(http.StatusOK, gin.H{
			"success":  true,
			"metadata": string(body[:]),
		})
	})

	r.Run("0.0.0.0:8080")
}
