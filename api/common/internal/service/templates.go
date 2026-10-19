package service

// MeasureSpec is one measure of an A-10 template with its advisory range.
type MeasureSpec struct {
	Name string  `json:"name"`
	Min  float64 `json:"min"`
	Max  float64 `json:"max"`
}

// Templates are the canonical A-10 field lists (flows/vault.md §2, Decided
// 2026-07-25; web/src/models/entities/measurement.ts is the client copy).
// A scan maps the customer's full template (A-10b), so capture.ready
// carries the list segmentation measures against.
var Templates = map[string][]MeasureSpec{
	"women": {
		{"shoulder", 30, 60}, {"bust", 60, 160}, {"under_bust", 55, 140}, {"bust_span", 12, 30}, {"waist", 50, 150},
		{"shoulder_to_bust_point", 18, 40}, {"shoulder_to_under_bust", 25, 50}, {"shoulder_to_waist", 30, 60},
		{"half_length", 30, 70}, {"waist_to_knee", 40, 75}, {"gown_length", 90, 170}, {"skirt_length", 40, 120},
		{"trouser_length", 80, 120}, {"thigh", 40, 90}, {"knee", 25, 60}, {"sleeve_length", 15, 70}, {"sleeve_width", 20, 50},
	},
	"men": {
		{"shoulder", 30, 60}, {"chest", 70, 160}, {"waist", 50, 150}, {"top_length", 55, 100}, {"thigh", 40, 90},
		{"hip", 70, 160}, {"knee", 25, 60}, {"shin", 20, 50}, {"waist_to_knee", 40, 75}, {"trouser_length", 80, 120},
		{"trouser_inseam", 60, 95}, {"biceps", 20, 50}, {"sleeve_length", 15, 70}, {"neck", 25, 55},
	},
}

// qcCopy is the retake guidance per code and pose (flows/vault.md §1,
// capture-qc.md §2).
func qcCopy(code, pose string) string {
	switch code {
	case "arms_position":
		if pose == "side" {
			return "Let your arms hang relaxed at your sides"
		}
		return "Keep arms slightly away from your body"
	case "no_body":
		return "Make sure your whole body is visible"
	case "multiple_bodies":
		return "Make sure you're alone in frame"
	case "partial_body":
		return "Include head to ankles"
	case "undecodable_image":
		return "That image couldn't be read — try another photo"
	case "low_resolution":
		return "Move closer or use a higher-quality camera"
	case "poor_lighting":
		return "Find better lighting — avoid strong backlight"
	case "blurry":
		return "Hold steady and retake"
	case "not_frontal":
		return "Face the camera straight on"
	case "camera_tilt":
		return "Hold the phone upright"
	case "too_far":
		return "Move closer — fill more of the frame"
	case "not_side_profile":
		return "Turn your right side to the camera"
	case "pipeline_busy":
		return "Measuring took too long — try again"
	}
	return "Retake the photo"
}
