package hello
import "testing"
func TestPass(t *testing.T) {
  if 1 != 1 { t.Fatalf("unexpected failure") }
}
