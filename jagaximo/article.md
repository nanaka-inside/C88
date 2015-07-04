Title: 冴えないSparkの育て方
Author: @jagaximo

こんにちは！ @jagaximoといいます。
最近、IBMが3500人をSpark関連に投入するというような感じで最近盛り上がっています。
でもいざ調べて使ってみようとしても、何ができて、どういううれしみがあるかイマイチ分からない。みたいなことになるかもしれません。
この記事では、Sparkをどう始めればいいのか。さらに詰まった時にどうすればいいのかを少し紹介します

Sparkって？
=========

OSSの駆け込み寺ことApach Foundationのトップレベルプロダクトの一つで、Hadoopからの流れを汲む、分散処理基盤です。
大きなデータの塊を多数の小さなデータの塊に細かく分割して、それをクラスタの各マシンに渡し、クラスタはそれぞれデータを処理して、最後にマージする、というような手順を踏んで計算します。この仕組がいわゆるMapReduceです。
HadoopもSparkもこのMapReduceの手順を踏んでタスクを処理する点では同じです。

ではSparkの何が嬉しいのか。Sparkのトップページにいくとこう書いてあります

```
Run programs up to 100x faster than Hadoop MapReduce in memory, or 10x faster on disk.
```

100倍早い。これはSparkがHadoopと違って一回のMapReduceタスクの結果を、それぞれのWorkerのメモリに乗っけるので、HDFSに保存する時のIOコストがかからないためです。
他にも、タスクの記述がHadoopよりも簡単、ビルトインのライブラリが優秀、ライブラリの作りやすさなどが挙げられますが、ここでは割愛します。検索すれば割と簡単にヒットすると思います。

Sparkセットアップ
================

Sparkはマシンクラスタを用意して計算させるのが本懐ですが、一つのマシンで動かす事もできます。まずそれで動かしてみましょう

## ダウンロード＆ビルド

いろんな方法がありますが、今回はソースをビルドして動かしてみます。
バージョンはこの記事を書いている時点の最新リリースである1.4.0を使用します。
また、この記事におけるSparkアプリケーションのコードはすべてこの1.4.0を基準に書かれています。

```bash
wget http://www.apache.org/dyn/closer.cgi/spark/spark-1.4.0/spark-1.4.0.tgz
cd spark-1.4.0
build/sbt -Pyarn -Phadoop-2.3 assembly
```
sbtでもmavenでも、ビルドは可能です。今回はsbtを利用しましたが、一回sbtビルドができなくなったまま放置されてた期間があるので、mavenビルドのほうが安全かもしれません

巨大なScalaプロダクトなのでビルドには時間がかかります。ビルドしている間にイカでもプレイして遊んでいればいいと思います

## データを用意する
Sparkはなんか色々大きなデータを分析するための技術です。ので、でっかいデータを食わせてみないと始まりません
とはいえ本当に大きなデータを食べさせてもさすがに動かなかったり、時間がかかったりしてだるいので、小さなデータから始めましょう

今回は、ニコニコデータセットのニコニコ大百科データのヘッダデータを使ってみたいと思います。

データの定義は、以下のようになっています

```
カラム: 記事ID, 記事タイトル, 記事ヨミ, 記事種類(a:単語,v:動画,i:商品,l:生放送), 記事作成日時
※ユーザページ、ユーザIDは削除されています。
```

これがCSV形式で入っているようです。
データを落としてみると、年度ごとにCSVが分かれていてめんどくさかったのでマージしちゃいました

```bash
cd path/to/data/dir
touch all.csv
ls -1 | grep head | xargs -I{} cat {} >> all.csv
```

## クエリを書く
クエリはScala, Java, Python, Rでかけます。
今回、僕がScala好きなのでScalaで書いてます。

### クエリを書くための前知識
SparkはRDDとDataFrameという単位のデータを持っています。



### 書き置き

```scala
import sys.process._
// Zeppelin creates and injects sc (SparkContext) and sqlContext (HiveContext or SqlContext)
// So you don't need create them manually
import sqlContext.implicits._
import scala.util.Try

val zeppelinHome = ("pwd" !!).replace("\n", "")
// val bankText = sc.textFile(s"file:///Users/jagaximo/data/head/all.csv")

val articleText = sc.textFile("file:///Users/jagaximo/data/head/all.csv")

// 記事ID, 記事タイトル, 記事ヨミ, 記事種類(a:単語,v:動画,i:商品,l:生放送), 記事作成日時
case class Article(id: Int, title: String, articleType: String, createDate: Long)

val articles = articleText.map(_.split(",")).map(a => Try{
    val splits = a.map(_.init.tail.toString)
    Article(
        splits(0).toInt,
        splits(1),
        splits(3) match {
            case "a" => "word"
            case "v" => "video"
            case "i" => "item"
            case "l" => "live"
        },
        splits(4).take(6).toLong
    )
}).filter(_.isSuccess).map(_.get).toDF

articles.registerTempTable("article")


%sql
select createDate, count(articleType="word" or null) word, count(articleType="video" or null) video, count(articleType="item" or null) item, count(articleType="live" or null) live
from article
group By createDate
order by createDate
```
