import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xkcd/api/comic_api_client.dart';
import 'package:xkcd/data/comic.dart';
import 'package:xkcd/pages/comic_page.dart';
import 'package:xkcd/providers/preferences.dart';
import 'package:xkcd/utils/app_localizations.dart';

class FavoritesPage extends StatefulWidget {
  static final String favoritesPageRoute = '/favorites-page';

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final SharedPreferences prefs = Preferences.prefs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('favorites')),
        elevation: 0.0,
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: _buildFavoritesList(),
      ),
    );
  }

  _buildFavoritesList() {
    final favorites = prefs.getStringList('favorites');
    if (favorites != null && favorites.isNotEmpty) {
      return FutureBuilder(
        future: ComicApiClient.fetchComics(favorites),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              if (snapshot.hasError) {
                debugPrint(snapshot.toString());
                return Container(width: 0.0, height: 0.0);
              } else {
                var data = snapshot.data;
                if (data != null && data is List) {
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      Comic comic = data[index];
                      return _buildListTile(index, context, comic);
                    },
                  );
                }
              }
          }
        },
      );
    }
    return Center(
      child: Text(AppLocalizations.of(context).get('nothing_here')),
    );
  }

  _buildListTile(int index, BuildContext context, Comic comic) {
    return Dismissible(
      key: Key(index.toString()),
      onDismissed: (direction) {
        _removeFavorite(context, comic);
      },
      background: Container(
        color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Icon(Icons.delete_sweep, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Icon(Icons.delete_sweep, color: Colors.white),
            ),
          ],
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(10.0),
        leading: Hero(
          tag: 'hero-${comic.num}',
          child: Image.network(
            comic.img,
            width: 50.0,
          ),
        ),
        title: Text(comic.title),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            maintainState: true,
            builder: (context) {
              return ComicPage(comic);
            },
          ));
        },
      ),
    );
  }

  _removeFavorite(BuildContext context, Comic comic) {
    var num = comic.num.toString();
    List<String> favorites = prefs.getStringList('favorites');
    if (favorites == null || favorites.isEmpty) {
      return;
    }
    if (favorites.contains(num)) {
      favorites.remove(num);
    }
    prefs.setStringList('favorites', favorites);

    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text.rich(TextSpan(children: [
          TextSpan(
            text: '${comic.title}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' ${AppLocalizations.of(context).get('favorite_removed')}'),
        ])),
      ),
    );
  }
}