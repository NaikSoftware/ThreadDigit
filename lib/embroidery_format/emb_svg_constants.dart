/// Shared constants defining the `.emb.svg` embroidery format contract.
///
/// The format is a parametric SVG: a document is an ordered list of embroidery
/// elements (lines, manual stitches, fills, satin columns). Parameters that
/// Ink/Stitch understands are written in its own namespace so Ink/Stitch can
/// read the same file. Data Ink/Stitch has no concept of (thread catalog,
/// element type discriminator, future custom parameters) lives in the [emb]
/// namespace, which Ink/Stitch and generic viewers ignore.
class EmbSvgConstants {
  EmbSvgConstants._();

  /// Recommended file extension for embroidery SVG documents.
  static const String fileExtension = '.emb.svg';

  /// Current format version, written to [attrVersion] on the root element.
  static const String formatVersion = '2.0';

  /// Standard SVG namespace.
  static const String svgNamespace = 'http://www.w3.org/2000/svg';

  /// Ink/Stitch namespace. Reused verbatim so Ink/Stitch reads our parameters.
  static const String inkstitchNamespace = 'http://inkstitch.org/namespace';
  static const String inkstitchPrefix = 'inkstitch';

  /// Our own namespace for data Ink/Stitch does not model.
  static const String embNamespace = 'http://thread-digit.app/embroidery/v1';
  static const String embPrefix = 'emb';

  /// All coordinates and physical values are expressed in millimeters.
  static const String unitMillimeters = 'mm';

  // --- Root <svg> attributes (emb-namespaced) ---
  static const String attrVersion = 'version';
  static const String attrUnits = 'units';

  // --- <metadata> embroidery elements (emb-namespaced) ---
  static const String elDesign = 'design';
  static const String elPalette = 'palette';
  static const String elThread = 'thread';
  static const String elMachine = 'machine';

  // --- <emb:design> attributes ---
  static const String attrName = 'name';
  static const String attrAuthor = 'author';
  static const String attrNotes = 'notes';
  static const String attrCreated = 'created';
  static const String attrElementCount = 'elementCount';
  static const String attrWidthMm = 'widthMm';
  static const String attrHeightMm = 'heightMm';

  // --- <emb:thread> palette entry attributes ---
  static const String attrThreadId = 'id';
  static const String attrCatalog = 'catalog';
  static const String attrCode = 'code';
  static const String attrRgb = 'rgb';
  static const String attrNeedle = 'needle';
  static const String attrPercentage = 'percentage';

  // --- <emb:machine> attributes ---
  static const String attrMachineName = 'name';

  // --- Per-element emb-namespaced attributes ---
  /// Authoritative element-type discriminator. The reader trusts this; a file
  /// without it falls back to Ink/Stitch-style detection.
  static const String attrElementType = 'elementType';

  /// References an [elThread] palette entry by its [attrThreadId].
  static const String attrElementThreadId = 'threadId';

  // --- Element type values (for [attrElementType]) ---
  static const String typeLine = 'line';
  static const String typeManualStitch = 'manual_stitch';
  static const String typeFill = 'fill';
  static const String typePhotoStitch = 'photo_stitch';
  static const String typeSatinColumn = 'satin_column';

  // --- Ink/Stitch parameter names (written as inkstitch:<name>) ---
  static const String paramStrokeMethod = 'stroke_method';
  static const String paramRunningStitchLengthMm = 'running_stitch_length_mm';
  static const String paramRepeats = 'repeats';
  static const String paramBeanStitchRepeats = 'bean_stitch_repeats';
  static const String paramSatinColumn = 'satin_column';
  static const String paramFillMethod = 'fill_method';
  static const String paramAngle = 'angle';
  static const String paramRowSpacingMm = 'row_spacing_mm';
  static const String paramMaxStitchLengthMm = 'max_stitch_length_mm';
  static const String paramStaggers = 'staggers';
  static const String paramExpandMm = 'expand_mm';
  static const String paramZigzagSpacingMm = 'zigzag_spacing_mm';
  static const String paramPullCompensationMm = 'pull_compensation_mm';
  static const String paramTrimAfter = 'trim_after';
  static const String paramStopAfter = 'stop_after';

  // --- Ink/Stitch parameter values ---
  static const String valRunningStitch = 'running_stitch';
  static const String valManualStitch = 'manual_stitch';
  static const String valAutoFill = 'auto_fill';
  static const String valTrue = 'true';
  static const String valFalse = 'false';

  // --- Default parameter values ---
  static const double defaultRunningStitchLengthMm = 2.5;
  static const int defaultRepeats = 1;
  static const String defaultBeanStitchRepeats = '0';
  static const double defaultFillAngle = 0.0;
  static const double defaultRowSpacingMm = 0.25;
  static const double defaultMaxStitchLengthMm = 4.0;
  static const int defaultStaggers = 4;
  static const double defaultExpandMm = 0.0;
  static const double defaultZigzagSpacingMm = 0.4;
  static const double defaultPullCompensationMm = 0.0;

  // --- Standard SVG presentation values ---
  static const double defaultStrokeWidthMm = 0.3;
  static const String strokeLineCap = 'round';
  static const String strokeLineJoin = 'round';
  static const String none = 'none';
}
