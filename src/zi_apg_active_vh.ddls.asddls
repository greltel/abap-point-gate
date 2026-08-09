@EndUserText.label: 'Value Help for Activation Status'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_APG_ACTIVE_VH'
@ObjectModel.resultSet.sizeCategory: #XS
define custom entity ZI_APG_ACTIVE_VH
{
      @EndUserText.label: 'Activation Status'
  key ActivationStatus : zapg_active;
      @EndUserText.label: 'Description'
      Description      : abap.char(60);
}
