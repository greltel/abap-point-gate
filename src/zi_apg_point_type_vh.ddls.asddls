@EndUserText.label: 'Value Help for Point Type'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_APG_POINT_TYPE_VH'
@ObjectModel.resultSet.sizeCategory: #XS
define custom entity ZI_APG_POINT_TYPE_VH
{
      @EndUserText.label: 'Point Type'
  key PointType   : zapg_point_type;
      @EndUserText.label: 'Description'
      Description : abap.char(60);
}
