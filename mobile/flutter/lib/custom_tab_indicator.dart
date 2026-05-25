
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

class CustomTabIndicator extends Decoration {

  @override
  _CustomPainter createBoxPainter([VoidCallback? onChanged]) {
    return new _CustomPainter(this, onChanged!);
  }

}

class _CustomPainter extends BoxPainter {

  final CustomTabIndicator decoration;

  _CustomPainter(this.decoration, VoidCallback onChanged)
      : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration, ) {
    assert(configuration.size != null);

    double indicatorHeight = 30;

    final Rect rect = Offset(offset.dx, (configuration.size!.height/2)-indicatorHeight/2) & Size(configuration.size!.width, indicatorHeight);
    final Paint paint = Paint();
    paint.color = Color.fromARGB(255,0,113,254);
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(4)), paint);
  }

}
