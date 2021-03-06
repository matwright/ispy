import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ispy/blocs/camera/bloc.dart';
import 'package:ispy/blocs/sensors/sensors_bloc.dart';
import 'package:ispy/data/spied_model.dart';
import './bloc.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final CameraBloc cameraBloc;

  StreamSubscription cameraBlocSubscription;
  CameraController cameraController;
  SpiedModel spiedModel;
  String player = SearchState.PLAYER_AI;
  SearchBloc(this.cameraBloc, this.player) : super(InitialSearchState(player)) {
    cameraBlocSubscription = cameraBloc.listen((state) {
      print('***STATE*** ' + state.toString());
      if (state is CameraStartedState) {
        cameraController = state.controller;
        this.add(LoadSearchEvent());
      } else if (state is ImageCapturedState) {
        spiedModel = state.spiedModel;
        if (null == spiedModel.word) {
          throw Exception('word not set');
        }
        this.add(ImageSelectedEvent());
      }
    });
  }

  @override
  Future<void> close() {
    cameraBlocSubscription.cancel();
    return super.close();
  }

  @override
  Stream<SearchState> mapEventToState(
    SearchEvent event,
  ) async* {
    if (event is LoadSearchEvent) {
      yield* _mapLoadSearchEventtoState();
    } else if (event is ImageSelectedEvent) {
      print('stop sensors');
      yield* _mapImageSelectedEventToState(event);
    }
  }

  Stream<SearchClueState> _mapImageSelectedEventToState(
      ImageSelectedEvent event) async* {
    AssetsAudioPlayer.newPlayer().open(
        Audio("assets/capture.mp3"
            ,metas: Metas(  id:'intro')
        ),
        autoStart: true,
        showNotification: true,

        playInBackground: PlayInBackground.disabledPause
    );
    await new Future.delayed(const Duration(seconds: 1));
    print("***SearchClueState***");
    print(spiedModel.word.toString());
    String clue = "I spy with my little eye something beginning with " +
        spiedModel.word.toString().substring(0, 1);

    FlutterTts flutterTts = FlutterTts();
    await flutterTts.speak(clue);
    yield SearchClueState(spiedModel, player);
  }

  Stream<SearchLoadedState> _mapLoadSearchEventtoState() async* {
    yield SearchLoadedState(cameraController, player);
  }
}
