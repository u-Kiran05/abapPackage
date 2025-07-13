@AbapCatalog.sqlViewName: 'ZV_INC_MGMT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'EHSM INCIDENT MANAGEMENT V1'
@Metadata.ignorePropagatedAnnotations: true
@OData.publish: true
define view ZEHSM_INC_MGMT_V1 as select from zsv_inc_mgmt
{
    key id                 as Id,
        created_on         as CreatedOn,
        created_by         as CreatedBy,
        changed_by         as ChangedBy,
        incident_cat       as IncidentCategory,
        inc_rec_status     as IncidentStatus,
        archiving_stat     as ArchivingStatus,
        incident_id        as IncidentId,
        title              as Title,
        plant_id           as PlantId,
        location           as Location,
        incident_grp       as IncidentGroup
}
