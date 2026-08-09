@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Maintain Handlers - Projection'
@Metadata.allowExtensions: true
define view entity ZC_APG_GateHandle
  as projection on ZR_APG_GateHandle
{
  key PointId,
  key SeqNo,
      HandlerClass,
      Active,
      ActiveCriticality,
      ActivationClass,
      Param1,
      Param2,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _Point : redirected to parent ZC_APG_Point
}
