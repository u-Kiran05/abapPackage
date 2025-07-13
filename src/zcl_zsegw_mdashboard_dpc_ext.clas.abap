class ZCL_ZSEGW_MDASHBOARD_DPC_EXT definition
  public
  inheriting from ZCL_ZSEGW_MDASHBOARD_DPC
  create public .

public section.
protected section.

  methods ZNOTIFSET_GET_ENTITYSET
    redefinition .
  methods ZWORKORDERSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSEGW_MDASHBOARD_DPC_EXT IMPLEMENTATION.


METHOD znotifset_get_entityset.

  DATA: lt_entityset     TYPE zmen_notif_t,
        lt_filter_select TYPE /iwbep/t_mgw_select_option,
        ls_filter_select TYPE /iwbep/s_mgw_select_option,
        lv_empid         TYPE pernr_d.

  " Get filters
  lt_filter_select = it_filter_select_options.

  " Get EmpId from flat filters
  LOOP AT lt_filter_select INTO ls_filter_select.
    IF to_upper( ls_filter_select-property ) = 'EMPID'.

      " Get directly from first option (no need for RANGES type)
      IF lines( ls_filter_select-select_options ) > 0.
        lv_empid = ls_filter_select-select_options[ 1 ]-low.
      ENDIF.

      EXIT.
    ENDIF.
  ENDLOOP.

  " Validate input
  IF lv_empid IS INITIAL.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid  = /iwbep/cx_mgw_busi_exception=>business_error
        message = 'EMP_ID filter is required.'.
  ENDIF.

  " Fetch assigned notifications
  SELECT a~qmnum, a~qmart, a~qmtxt, a~priok, a~qmdat, a~strmn,
         a~tplnr, a~equnr, a~arbpl, a~ingrp, a~ernam,
         z~emp_id
    INTO CORRESPONDING FIELDS OF TABLE @lt_entityset
    FROM viqmel AS a
    INNER JOIN znotif_assign AS z
      ON a~qmnum = z~qmnum
    WHERE z~emp_id = @lv_empid.

  et_entityset = lt_entityset.

ENDMETHOD.


METHOD zworkorderset_get_entityset.

  DATA: lt_entityset TYPE zmen_worko_t,
        ls_entity    TYPE zmen_worko_s.

  DATA: lt_assign TYPE STANDARD TABLE OF zmain_woassign,
        ls_assign TYPE zmain_woassign,
        lv_objnr  TYPE aufk-objnr,
        lv_empid  TYPE pernr_d.

*--- Extract EmpId filter (case-sensitive from SEGW)
  LOOP AT it_filter_select_options INTO DATA(ls_filter).
    IF ls_filter-property = 'EmpId'.  " <-- case-sensitive match to SEGW
      lv_empid = ls_filter-select_options[ 1 ]-low.
    ENDIF.
  ENDLOOP.

*--- Conditional fetch based on filter
  IF lv_empid IS INITIAL.
    SELECT * FROM zmain_woassign INTO TABLE @lt_assign.
  ELSE.
    SELECT * FROM zmain_woassign
      WHERE emp_id = @lv_empid
      INTO TABLE @lt_assign.
  ENDIF.

*--- Loop through and build entityset
  LOOP AT lt_assign INTO ls_assign.
    CLEAR ls_entity.

    ls_entity-aufnr    = ls_assign-aufnr.
    ls_entity-emp_id   = ls_assign-emp_id.

*--- AUFK header data
    SELECT SINGLE auart, ktext, ernam, erdat, bukrs, kostl, kostv,
                  gsber, stort, sowrk, scope, objnr
      INTO (@ls_entity-auart, @ls_entity-ktext, @ls_entity-ernam, @ls_entity-erdat,
            @ls_entity-bukrs, @ls_entity-kostl, @ls_entity-kostv,
            @ls_entity-gsber, @ls_entity-stort, @ls_entity-sowrk,
            @ls_entity-scope, @lv_objnr)
      FROM aufk
      WHERE aufnr = @ls_assign-aufnr.

*--- Planned start date
    SELECT SINGLE gstrp INTO @ls_entity-gstrp
      FROM afko
      WHERE aufnr = @ls_assign-aufnr.

*--- Equipment number from EQUI
    SELECT SINGLE equnr INTO @ls_entity-equnr
      FROM equi
      WHERE objnr = @lv_objnr.

*--- Equipment description
    IF sy-subrc = 0 AND ls_entity-equnr IS NOT INITIAL.
      SELECT SINGLE eqktx INTO @ls_entity-eqktx
        FROM eqkt
        WHERE equnr = @ls_entity-equnr
          AND spras = @sy-langu.
    ENDIF.

    APPEND ls_entity TO et_entityset.
  ENDLOOP.

ENDMETHOD.
ENDCLASS.
