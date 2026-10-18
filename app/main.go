package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"runtime/debug"
)

// extraHandlers lets later stages register routes without touching main().
var extraHandlers = map[string]http.HandlerFunc{}

func main() {
	addr := ":8080"
	if v := os.Getenv("ADDR"); v != "" {
		addr = v
	}

	mux := http.NewServeMux()

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte("ok\n"))
	})

	mux.HandleFunc("/version", func(w http.ResponseWriter, _ *http.Request) {
		info, _ := debug.ReadBuildInfo()
		_ = json.NewEncoder(w).Encode(map[string]any{"go": info.GoVersion, "deps": len(info.Deps)})
	})

	for path, h := range extraHandlers {
		mux.HandleFunc(path, h)
	}

	log.Printf("app listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}
