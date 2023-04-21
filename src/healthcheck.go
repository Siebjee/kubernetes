package main

import (
  "flag"
  "net/http"
  "os"
  "fmt"
)

func main() {
  url  := flag.String("url", "http://127.0.0.1", "URL to check")
  flag.Parse()
  resp, err := http.Get( *url )    // Note pointer dereference using *

  // If there is an error or non-200 status, exit with 1 signaling unsuccessful check.
  if err != nil || resp.StatusCode != 200 {
    fmt.Println("Healthcheck failed for URL: ", *url )
    os.Exit(1)
  }
  fmt.Println("Healthcheck successful for URL: ", *url )
  os.Exit(0)
}
