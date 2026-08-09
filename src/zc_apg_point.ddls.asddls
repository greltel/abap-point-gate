@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Maintain Point - Projection'
@Metadata.allowExtensions: true
define root view entity ZC_APG_Point
  provider contract transactional_query
  as projection on ZR_APG_Point
{
  key PointId,
      Description,
      ModuleName,
      Active,
      ActiveCriticality,
      SrcMainProg,
      SrcInclude,
      SrcLine,
      PointTypeCode,
      ActivationClass,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _Gates : redirected to composition child ZC_APG_GateHandle
}
