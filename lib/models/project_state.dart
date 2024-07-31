import '../constants.dart';
import 'step_sequencer_state.dart';

class ProjectState {
  ProjectState({
    required this.stepCount,
    required this.tempo,
    required this.isLooping,
    required this.drumState,
    required this.pianoState,
    required this.bassState,
  });

  final int stepCount;
  final double tempo;
  final bool isLooping;
  final StepSequencerState drumState;
  final StepSequencerState pianoState;
  final StepSequencerState bassState;

  static ProjectState empty(int stepCount) {
    return ProjectState(
      stepCount: stepCount,
      tempo: Constants.INITIAL_TEMPO,
      isLooping: Constants.INITIAL_IS_LOOPING,
      drumState: StepSequencerState(),
      pianoState: StepSequencerState(),
      bassState: StepSequencerState(),
    );
  }

//
  static ProjectState demo() {
    //drums
    final drumState = StepSequencerState();
    drumState.setVelocity(0, 44, 0.75);
    //piano
    final pianoState = StepSequencerState();
    pianoState.setVelocity(47, 60, 0.9);
    //bass
    final bassState = StepSequencerState();

    return ProjectState(
      stepCount: 48,
      tempo: 480,
      isLooping: true,
      pianoState: pianoState,
      drumState: drumState,
      bassState: bassState,
    );
  }
}
