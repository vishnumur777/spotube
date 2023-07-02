import 'package:catcher/catcher.dart';
import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/components/library/playlist_generate/recommendation_attribute_dials.dart';
import 'package:spotube/extensions/map.dart';
import 'package:spotube/extensions/track.dart';
import 'package:spotube/hooks/use_spotify_infinite_query.dart';
import 'package:spotube/hooks/use_spotify_query.dart';
import 'package:spotube/pages/library/playlist_generate/playlist_generate.dart';
import 'package:spotube/provider/custom_spotify_endpoint_provider.dart';
import 'package:spotube/provider/user_preferences_provider.dart';

typedef RecommendationParameters = ({
  RecommendationAttribute acousticness,
  RecommendationAttribute danceability,
  RecommendationAttribute duration_ms,
  RecommendationAttribute energy,
  RecommendationAttribute instrumentalness,
  RecommendationAttribute key,
  RecommendationAttribute liveness,
  RecommendationAttribute loudness,
  RecommendationAttribute mode,
  RecommendationAttribute popularity,
  RecommendationAttribute speechiness,
  RecommendationAttribute tempo,
  RecommendationAttribute time_signature,
  RecommendationAttribute valence,
});

Map<String, num> recommendationAttributeToMap(RecommendationAttribute attr) => {
      "min": attr.min,
      "target": attr.target,
      "max": attr.max,
    };

({Map<String, num> min, Map<String, num> target, Map<String, num> max})
    recommendationParametersToMap(RecommendationParameters params) {
  final maxMap = <String, num>{
    if (params.acousticness != zeroValues)
      "acousticness": params.acousticness.max,
    if (params.danceability != zeroValues)
      "danceability": params.danceability.max,
    if (params.duration_ms != zeroValues) "duration_ms": params.duration_ms.max,
    if (params.energy != zeroValues) "energy": params.energy.max,
    if (params.instrumentalness != zeroValues)
      "instrumentalness": params.instrumentalness.max,
    if (params.key != zeroValues) "key": params.key.max,
    if (params.liveness != zeroValues) "liveness": params.liveness.max,
    if (params.loudness != zeroValues) "loudness": params.loudness.max,
    if (params.mode != zeroValues) "mode": params.mode.max,
    if (params.popularity != zeroValues) "popularity": params.popularity.max,
    if (params.speechiness != zeroValues) "speechiness": params.speechiness.max,
    if (params.tempo != zeroValues) "tempo": params.tempo.max,
    if (params.time_signature != zeroValues)
      "time_signature": params.time_signature.max,
    if (params.valence != zeroValues) "valence": params.valence.max,
  };
  final minMap = <String, num>{
    if (params.acousticness != zeroValues)
      "acousticness": params.acousticness.min,
    if (params.danceability != zeroValues)
      "danceability": params.danceability.min,
    if (params.duration_ms != zeroValues) "duration_ms": params.duration_ms.min,
    if (params.energy != zeroValues) "energy": params.energy.min,
    if (params.instrumentalness != zeroValues)
      "instrumentalness": params.instrumentalness.min,
    if (params.key != zeroValues) "key": params.key.min,
    if (params.liveness != zeroValues) "liveness": params.liveness.min,
    if (params.loudness != zeroValues) "loudness": params.loudness.min,
    if (params.mode != zeroValues) "mode": params.mode.min,
    if (params.popularity != zeroValues) "popularity": params.popularity.min,
    if (params.speechiness != zeroValues) "speechiness": params.speechiness.min,
    if (params.tempo != zeroValues) "tempo": params.tempo.min,
    if (params.time_signature != zeroValues)
      "time_signature": params.time_signature.min,
    if (params.valence != zeroValues) "valence": params.valence.min,
  };
  final targetMap = <String, num>{
    if (params.acousticness != zeroValues)
      "acousticness": params.acousticness.target,
    if (params.danceability != zeroValues)
      "danceability": params.danceability.target,
    if (params.duration_ms != zeroValues)
      "duration_ms": params.duration_ms.target,
    if (params.energy != zeroValues) "energy": params.energy.target,
    if (params.instrumentalness != zeroValues)
      "instrumentalness": params.instrumentalness.target,
    if (params.key != zeroValues) "key": params.key.target,
    if (params.liveness != zeroValues) "liveness": params.liveness.target,
    if (params.loudness != zeroValues) "loudness": params.loudness.target,
    if (params.mode != zeroValues) "mode": params.mode.target,
    if (params.popularity != zeroValues) "popularity": params.popularity.target,
    if (params.speechiness != zeroValues)
      "speechiness": params.speechiness.target,
    if (params.tempo != zeroValues) "tempo": params.tempo.target,
    if (params.time_signature != zeroValues)
      "time_signature": params.time_signature.target,
    if (params.valence != zeroValues) "valence": params.valence.target,
  };

  return (
    max: maxMap,
    min: minMap,
    target: targetMap,
  );
}

class PlaylistQueries {
  const PlaylistQueries();

  Query<bool, dynamic> doesUserFollow(
    WidgetRef ref,
    String playlistId,
    String userId,
  ) {
    return useSpotifyQuery<bool, dynamic>(
      "playlist-is-followed/$playlistId/$userId",
      (spotify) async {
        final result = await spotify.playlists.followedBy(playlistId, [userId]);
        return result.first;
      },
      ref: ref,
    );
  }

  Query<Iterable<PlaylistSimple>, dynamic> ofMine(WidgetRef ref) {
    return useSpotifyQuery<Iterable<PlaylistSimple>, dynamic>(
      "current-user-playlists",
      (spotify) {
        return spotify.playlists.me.all();
      },
      ref: ref,
    );
  }

  Future<List<Track>> tracksOf(String playlistId, SpotifyApi spotify) {
    if (playlistId == "user-liked-tracks") {
      return spotify.tracks.me.saved.all().then(
            (tracks) => tracks.map((e) => e.track!).toList(),
          );
    }
    return spotify.playlists.getTracksByPlaylistId(playlistId).all().then(
          (value) => value.toList(),
        );
  }

  Query<List<Track>, dynamic> tracksOfQuery(
    WidgetRef ref,
    String playlistId,
  ) {
    return useSpotifyQuery<List<Track>, dynamic>(
      "playlist-tracks/$playlistId",
      (spotify) => tracksOf(playlistId, spotify),
      jsonConfig: playlistId == "user-liked-tracks"
          ? JsonConfig(
              toJson: (tracks) => <String, dynamic>{
                'tracks': tracks.map((e) => e.toJson()).toList()
              },
              fromJson: (json) => (json['tracks'] as List)
                  .map((e) => Track.fromJson(
                        (e as Map).castKeyDeep<String>(),
                      ))
                  .toList(),
            )
          : null,
      ref: ref,
    );
  }

  InfiniteQuery<Page<PlaylistSimple>, dynamic, int> featured(
    WidgetRef ref,
  ) {
    return useSpotifyInfiniteQuery<Page<PlaylistSimple>, dynamic, int>(
      "featured-playlists",
      (pageParam, spotify) async {
        try {
          final playlists =
              await spotify.playlists.featured.getPage(5, pageParam);
          return playlists;
        } catch (e, stack) {
          Catcher.reportCheckedError(e, stack);
          rethrow;
        }
      },
      initialPage: 0,
      nextPage: (lastPage, lastPageData) {
        if (lastPageData.isLast || (lastPageData.items ?? []).length < 5) {
          return null;
        }
        return lastPageData.nextOffset;
      },
      ref: ref,
    );
  }

  Query<List<Track>, dynamic> generate(
    WidgetRef ref, {
    ({List<String> tracks, List<String> artists, List<String> genres})? seeds,
    RecommendationParameters? parameters,
    int limit = 20,
    String? market,
  }) {
    final marketOfPreference = ref.watch(
      userPreferencesProvider.select((s) => s.recommendationMarket),
    );
    final customSpotify = ref.watch(customSpotifyEndpointProvider);

    final parametersMap =
        parameters == null ? null : recommendationParametersToMap(parameters);

    final query = useQuery<List<Track>, dynamic>(
      "generate-playlist",
      () async {
        final tracks = await customSpotify.getRecommendations(
          limit: limit,
          market: market ?? marketOfPreference,
          max: parametersMap?.max,
          min: parametersMap?.min,
          target: parametersMap?.target,
          seedArtists: seeds?.artists,
          seedGenres: seeds?.genres,
          seedTracks: seeds?.tracks,
        );
        return tracks;
      },
    );

    useEffect(() {
      return ref.listenManual(
        customSpotifyEndpointProvider,
        (previous, next) {
          if (previous != next) {
            query.refresh();
          }
        },
      ).close;
    }, [query]);

    return query;
  }
}
