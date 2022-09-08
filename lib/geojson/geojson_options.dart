class GeoJSONOptions {
    Function? lineStringFunc;
    Function? lineStringStyle;
    Function? polygonFunc;
    Function? polygonStyle;
    Function? pointFunc;
    Function? pointWidgetFunc;
    Function? pointStyle;
    Function? overallStyleFunc;
    Function? clusterFunc;
    bool featuresHaveSameStyle;

    GeoJSONOptions({this.lineStringFunc, this.lineStringStyle, this.polygonFunc,
      this.polygonStyle, this.pointFunc, this.pointWidgetFunc, this.pointStyle,
      this.overallStyleFunc, this.clusterFunc, this.featuresHaveSameStyle = false});

}


