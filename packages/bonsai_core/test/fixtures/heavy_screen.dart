class HeavyScreen {
  dynamic build(dynamic context) {
    return StreamBuilder(
      builder: (context, snapshot) {
        return Column(
          children: [
            Text('1'),
            Text('2'),
            Text('3'),
            Text('4'),
            Text('5'),
            Text('6'),
            Text('7'),
            Text('8'),
            Text('9'),
            Text('10'),
            Text('11'),
            Text('12'),
            Text('13'),
            Text('14'),
            Text('15'),
            Text('16'),
            Text('17'),
            Text('18'),
            Text('19'),
            Text('20'),
          ],
        );
      },
    );
  }
}

class StreamBuilder {
  StreamBuilder({required dynamic builder});
}

class Column {
  Column({required List<dynamic> children});
}

class Text {
  Text(String value);
}

class Consumer {
  Consumer({required dynamic builder});
}

class Row {
  Row({required List<dynamic> children});
}

class Icon {
  Icon(String name);
}

class Snapshot {}
