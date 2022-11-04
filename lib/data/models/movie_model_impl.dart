import 'package:flutter/material.dart';
import 'package:movie_app/data/vos/actor_vo.dart';
import 'package:movie_app/data/vos/base_actor_vo.dart';
import 'package:movie_app/data/vos/credit_vo.dart';
import 'package:movie_app/data/vos/genre_vo.dart';
import 'package:movie_app/data/vos/movie_vo.dart';
import 'package:movie_app/network/movie_data_agent.dart';
import 'package:movie_app/network/retrofit_data_agent_impl.dart';
import 'package:movie_app/persistence/daos/actor_dao.dart';
import 'package:movie_app/persistence/daos/genre_dao.dart';
import 'package:movie_app/persistence/daos/movie_dao.dart';
import 'movie_model.dart';
import 'package:rxdart/rxdart.dart';

class MovieModelImpl extends MovieModel {
  MovieDataAgent mDataAgent = RetrofitDataAgentImpl();

  static final MovieModelImpl _singleton = MovieModelImpl._internal();

  factory MovieModelImpl() {
    return _singleton;
  }

  //testing

  MovieModelImpl._internal(){

    getNowPlayingMoviesFromDatabaseScopedModel();
    getPopularMoviesFromDatabaseScopedModel();
    getTopRelatedMoviesFromDatabaseScopedModel();
    getActorsScopedModel(1);
    getActorsFromDatabase();
    getGenresScopedModel();
    getGenreFromDatabaseScopedModel();
  }

  /// Daos
  MovieDao mMovieDao = MovieDao();
  ActorDao mActorDao = ActorDao();
  GenreDao mGenreDao = GenreDao();

  ///Home Page State
  List<MovieVO> mNowPlayingMovieList = [];
  List<MovieVO> mPopularMovieList = [];
  List<MovieVO> mShowCaseMovieList = [];
  List<GenreVO> mGenreList = [];
  List<MovieVO> mMoviesByGenreList = [];
  List<BaseActorVO> mActors = [];

  ///Movie Detail State
  MovieVO? mMovie;
  List<CreditVO> mActorList = [];
  List<CreditVO> mCreatorsList = [];

  

  @override
  Future<List<MovieVO>>? getNowPlayingMovies(int page) {
    // return mDataAgent.getNowPlayingMovies(page);
    return mDataAgent.getNowPlayingMovies(page)?.then((movies) async{

      debugPrint("now playing MovieModelImpl async database ${movies.length}");
      List<MovieVO> nowPlayingMovies = movies.map((movie){
        movie.isNowPlaying = true;
        movie.isPopular = false;
        movie.isTopRated = false;
        return movie;
      }).toList();

      mMovieDao.saveMovies(nowPlayingMovies);

      debugPrint("database list ${mMovieDao.getAllMovies()}");
      return Future.value(movies);
    }).catchError((error){
      debugPrint("now playing MovieModelImpl async database error ${error.toString()}");
    });
  }

  @override
  Future<List<MovieVO>>? getPopularMovies(int page) {
    // return mDataAgent.getPopularMovies(page);
    return mDataAgent.getPopularMovies(page)?.then((movies) {
      List<MovieVO> popularMovies = movies.map((movie){
        movie.isTopRated = false;
        movie.isPopular = true;
        movie.isNowPlaying = false;
        return movie;
      }).toList();
      mMovieDao.saveMovies(popularMovies);
      return Future.value(movies);
    });
  }

  @override
  Future<List<MovieVO>>? getTopRatedMovies(int page) {
    // return mDataAgent.getTopRatedMovies(page);
    return mDataAgent.getTopRatedMovies(page)?.then((movies) async{
      List<MovieVO> topRatedMovies = movies.map((movie) {
        movie.isNowPlaying = false;
        movie.isPopular = false;
        movie.isTopRated = true;
        return movie;
      }).toList();
      mMovieDao.saveMovies(topRatedMovies);
      return Future.value(movies);
    });
  }

  @override
  Future<List<GenreVO>>? getGenres() {
    // return mDataAgent.getGenres();
    return mDataAgent.getGenres()?.then((genres){
      mGenreDao.saveAllGenres(genres);
      return Future.value(genres);
    });
  }

  @override
  Future<List<MovieVO>>? getMoviesByGenre(int genreId) {
    return mDataAgent.getMoviesByGenre(genreId);

  }

  @override
  Future<List<ActorVO>>? getActors(int page) {
    return mDataAgent.getActors(page)?.then((actors){
      mActorDao.saveAllActors(actors);
      return Future.value(actors);
    });
  }

  @override
  Future<List<CreditVO>>? getCreditsByMovie(int movieId) {
    return mDataAgent.getCreditsByMovie(movieId);
  }

  @override
  Future<MovieVO>? getMovieDetails(int movieId) {
    return mDataAgent.getMovieDetails(movieId)?.then((movie) async {
      mMovieDao.saveSingleMovie(movie);
      return Future.value(movie);
    });
  }

  // Database

  @override
  Future<List<ActorVO>>? getActorsFromDatabase() {
    return Future.value(mActorDao.getAllActors());
  }

  @override
  Future<List<GenreVO>>? getGenresFromDatabase() {
    return Future.value(mGenreDao.getAllGenres());
  }

  @override
  Future<MovieVO>? getMovieDetailsFromDatabase(int movieId) {
    return Future.value(mMovieDao.getMovieById(movieId));
  }

  @override
  Future<List<MovieVO>>? getNowPlayingMoviesFromDatabase() {
    return Future.value(mMovieDao
            .getAllMovies()
            .where((movie) => movie.isNowPlaying == true)
            .toList());
  }

  @override
  Future<List<MovieVO>>? getPopularMoviesFromDatabase() {
    return Future.value(mMovieDao
        .getAllMovies()
        .where((movie) => movie.isPopular == true)
        .toList());
  }

  @override
  Future<List<MovieVO>>? getTopRatedMoviesFromDatabase() {
    return Future.value(mMovieDao
        .getAllMovies()
        .where((movie) => movie.isTopRated == true)
        .toList());
  }

  ///Reactive Programming
  @override
  Stream<List<MovieVO>> getNowPlayingMoviesFromDatabaseReactive() {
    this.getNowPlayingMovies(1);
    return mMovieDao
        .getAllMovieEventStream()
        .startWith(mMovieDao.getNowPlayingMovieStream())
        .map((event) => mMovieDao.getNowPlayingMovie());
  }

  @override
  Stream<List<MovieVO>> getNowTopRelatedMoviesFromDatabaseReactive() {
    this.getTopRatedMovies(1);
    return mMovieDao
        .getAllMovieEventStream()
        .startWith(mMovieDao.getTopRatedMovieStream())
        .map((event) => mMovieDao.getTopRatedMovie());
  }

  @override
  Stream<List<MovieVO>> getPopularMoviesFromDatabaseReactive() {
    this.getPopularMovies(1);
    return mMovieDao
        .getAllMovieEventStream()
        .startWith(mMovieDao.getPopularMovieStream())
        .map((event) => mMovieDao.getPopularMovie());
  }

  /// Scoped Model and Scoped Model Database
  @override
  void getActorsFromDatabaseScopedModel() {
    // TODO: implement getActorsFromDatabaseScopedModel
   mActors =  mActorDao.getAllActors();
   notifyListeners();
  }

  @override
  void getActorsScopedModel(int page) {
    // TODO: implement getActorsScopedModel
    mDataAgent.getActors(page)?.then((actors) {
      mActorDao.saveAllActors(actors);
      mActors = actors;
      notifyListeners();
    });

  }

  @override
  void getGenreFromDatabaseScopedModel() {
    // TODO: implement getGenreFromDatabaseScopedModel
    mGenreList = mGenreDao.getAllGenres();
    notifyListeners();
  }

  @override
  void getGenresScopedModel() {
    // TODO: implement getGenresScopedModel
    mDataAgent.getGenres()?.then((genres) {
      mGenreDao.saveAllGenres(genres);
      mGenreList = genres;
      getMoviesByGenre(genres.first.id ?? 0)?.then((movieByGenreList) {
        mMoviesByGenreList = movieByGenreList;
        notifyListeners();
      });
      notifyListeners();
      return Future.value(genres);
    });
  }

  @override
  void getMoviesByGenresScopedModel(int genreId) {
    // TODO: implement getMoviesByGenresScopedModel

    mDataAgent.getMoviesByGenre(genreId)?.then((movieList) {
      mMoviesByGenreList = movieList;
      notifyListeners();
    });

  }

  @override
  void getTopRelatedMoviesFromDatabaseScopedModel() {
    // TODO: implement getTopRelatedMoviesFromDatabaseScopedModel
    this.getTopRatedMovies(1);
    mMovieDao
        .getAllMovieEventStream()
        .startWith(mMovieDao.getTopRatedMovieStream())
        .map((event) => mMovieDao.getTopRatedMovie())
        .first
        .then((movieList) {
      mShowCaseMovieList = movieList;
      notifyListeners();
    });
  }

  @override
  void getPopularMoviesFromDatabaseScopedModel() {
    // TODO: implement getPopularMoviesFromDatabaseScopedModel
    this.getPopularMovies(1);
    mMovieDao
        .getAllMovieEventStream()
        .startWith(mMovieDao.getPopularMovieStream())
        .map((event) => mMovieDao.getPopularMovie())
        .first
        .then((movieList) {
      mPopularMovieList = movieList;
      notifyListeners();
    });
  }

  @override
  void getNowPlayingMoviesFromDatabaseScopedModel() {
    // TODO: implement getNowPlayingMoviesFromDatabaseScopedModel
    this.getNowPlayingMovies(1);
    mMovieDao
        .getAllMovieEventStream()
        .startWith(mMovieDao.getNowPlayingMovieStream())
        .map((event) => mMovieDao.getNowPlayingMovie())
        .first
        .then((movieList) {
      mNowPlayingMovieList = movieList;
      notifyListeners();
    });
  }

  @override
  void getCreditsByMovieScopedModel(int movieId) {
    // TODO: implement getCreditsByMovieScopedModel
    mDataAgent.getCreditsByMovie(movieId)?.then((creditList) {
      mActorList = creditList.where((credit) => credit.isActor()).toList();
      mCreatorsList = creditList.where((credit) => credit.isCreator()).toList();
      notifyListeners();
    });
  }

  @override
  void getMovieDetailsFromDatabaseScopedModel(int movieId) {
    // TODO: implement getMovieDetailsFromDatabaseScopedModel
    mMovie = mMovieDao.getMovieById(movieId);
    notifyListeners();
  }

  @override
  void getMovieDetailsScopedModel(int movieId) {
    // TODO: implement getMovieDetailsScopedModel

    mDataAgent.getMovieDetails(movieId)?.then((movie) async {
      mMovieDao.saveSingleMovie(movie);
      mMovie = movie;
      notifyListeners();

    });
  }
}
