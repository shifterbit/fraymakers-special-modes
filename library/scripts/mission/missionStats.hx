// Assist stats for Template Assist

// Define some states for our state machine
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;

{
	spriteContent: self.getResource().getContent("missionPrompt"),
	initialState: STATE_IDLE,
	stateTransitionMapOverrides: [
		STATE_IDLE => {
			animation: "empty"
		}
	],
	gravity: 0,
}
