@AbapCatalog.sqlViewName: 'ZQMPLANTVIEW'
@AbapCatalog.compiler.compareFilter: true

@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Quality Inspection Lot View'
@Metadata.ignorePropagatedAnnotations: true
@OData.publish: true

define view ZQM_INSPECTIONLOT_CDS
  with parameters
    p_plant : werks_d
as select from qals
  inner join qave on qals.prueflos = qave.prueflos
{
  key qals.prueflos       as inspection_lot,
      qals.werk           as plant,
      qals.selmatnr       as material,
      qals.art            as inspection_type,
      qals.enstehdat      as created_on,
      qals.pastrterm      as start_date,
      qals.paendterm      as end_date,
      qals.herkunft       as quantity,
      qals.mengeneinh     as unit,
      qals.ktextmat       as material_text,
      qave.kzart          as characteristic_type,
      qave.vcode          as usage_decision
}
where qals.werk = :p_plant
