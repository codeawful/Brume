import java.awt.Font;
import java.awt.Shape;
import java.awt.font.FontRenderContext;
import java.awt.font.GlyphVector;
import java.awt.geom.AffineTransform;
import java.awt.geom.PathIterator;
import java.awt.geom.Rectangle2D;
import java.io.PrintWriter;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/**
 * JDK-only smoke test for the most important non-Processing assumption in Field Lab:
 * Java can give us a glyph outline, flatten it, normalize it, and export it as SVG.
 */
public class GlyphCoreSmokeTest {
    record Pt(double x, double y) {}

    public static void main(String[] args) throws Exception {
        Path out = args.length > 0 ? Path.of(args[0]) : Path.of("core-smoke-B.svg");
        Font font = new Font("Serif", Font.PLAIN, 1000);
        FontRenderContext frc = new FontRenderContext(new AffineTransform(), true, true);
        GlyphVector gv = font.createGlyphVector(frc, "B");
        Shape shape = gv.getOutline();
        Rectangle2D b = shape.getBounds2D();
        double maxDim = Math.max(b.getWidth(), b.getHeight());
        double padX = (1.0 - b.getWidth()/maxDim) * .5;
        double padY = (1.0 - b.getHeight()/maxDim) * .5;

        List<List<Pt>> contours = new ArrayList<>();
        List<Pt> current = null;
        PathIterator it = shape.getPathIterator(null, 0.85);
        double[] c = new double[6];
        int points = 0;
        while (!it.isDone()) {
            int type = it.currentSegment(c);
            if (type == PathIterator.SEG_MOVETO) {
                current = new ArrayList<>();
                contours.add(current);
                current.add(norm(c[0], c[1], b, maxDim, padX, padY));
                points++;
            } else if (type == PathIterator.SEG_LINETO && current != null) {
                current.add(norm(c[0], c[1], b, maxDim, padX, padY));
                points++;
            } else if (type == PathIterator.SEG_CLOSE) {
                current = null;
            }
            it.next();
        }

        try (PrintWriter pw = new PrintWriter(out.toFile())) {
            pw.println("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 1000 1000\">");
            pw.print("<path fill=\"#111111\" fill-rule=\"evenodd\" d=\"");
            for (List<Pt> contour : contours) {
                if (contour.isEmpty()) continue;
                Pt first = contour.get(0);
                pw.printf("M %.3f %.3f ", 80 + first.x()*840, 80 + first.y()*840);
                for (int i=1; i<contour.size(); i++) {
                    Pt p = contour.get(i);
                    pw.printf("L %.3f %.3f ", 80 + p.x()*840, 80 + p.y()*840);
                }
                pw.print("Z ");
            }
            pw.println("\"/></svg>");
        }

        System.out.println("OK: extracted " + contours.size() + " contours / " + points + " points");
        System.out.println("SVG: " + out.toAbsolutePath());
    }

    static Pt norm(double x, double y, Rectangle2D b, double maxDim, double padX, double padY) {
        return new Pt(
            padX + (x - b.getX()) / maxDim,
            padY + (y - b.getY()) / maxDim
        );
    }
}
