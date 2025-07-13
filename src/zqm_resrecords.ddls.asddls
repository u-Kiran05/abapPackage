@AbapCatalog.sqlViewName: 'ZQMRESRECORD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'QUALITY RESULT RECORDS'
@Metadata.ignorePropagatedAnnotations: true
@OData.publish: true

define view ZQM_RESRECORDS
  with parameters
    p_plant : werks_d
  as select from qamr as a
    inner join qals as b on a.prueflos = b.prueflos
    inner join qave as c on a.prueflos = c.prueflos
{
  key a.prueflos      as inspection_lot,
      a.vorglfnr      as operation_number,
      a.merknr        as characteristic_number,
      a.mbewertg      as measured_value,
      b.werk          as plant,
      b.art           as inspection_type,
      b.objnr         as object_number,
      b.obtyp         as object_type,
      b.stat35        as status,
      b.pastrterm     as start_date,
      b.paendterm     as end_date,
      b.herkunft      as quantity,
      b.mengeneinh    as unit,
      b.ktextmat      as material_text,
      c.vcode         as usage_decision
}
where b.werk = :p_plant
