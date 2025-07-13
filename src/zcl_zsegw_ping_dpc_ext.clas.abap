class ZCL_ZSEGW_PING_DPC_EXT definition
  public
  inheriting from ZCL_ZSEGW_PING_DPC
  create public .

public section.
protected section.

  methods PINGSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSEGW_PING_DPC_EXT IMPLEMENTATION.


METHOD pingset_get_entityset.

  DATA: ls_entity TYPE zcl_zsegw_ping_mpc=>ts_ping.

  " Clear the response table
  CLEAR et_entityset.

  " Set static ping message
  ls_entity-message = 'SAP is up and running'.

  " Append the record to the response table
  APPEND ls_entity TO et_entityset.

ENDMETHOD.
ENDCLASS.
