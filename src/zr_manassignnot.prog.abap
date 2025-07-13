*&---------------------------------------------------------------------*
*& Report ZR_MANASSIGNNOT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZR_MANASSIGNNOT.

PARAMETERS: p_qmnum TYPE qmel-qmnum OBLIGATORY,
            p_empid TYPE pernr_d     OBLIGATORY.

*--- Work Areas
DATA: lv_notif  TYPE qmel-qmnum,
      wa_assign TYPE znotif_assign.

*--- Check if Notification Exists
START-OF-SELECTION.

  SELECT SINGLE qmnum
    INTO lv_notif
    FROM qmel
    WHERE qmnum = p_qmnum.

  IF sy-subrc <> 0.
    MESSAGE 'Notification does not exist.' TYPE 'E'.
  ENDIF.

*--- Check if Notification Already Assigned
  SELECT SINGLE qmnum
    INTO lv_notif
    FROM znotif_assign
    WHERE qmnum = p_qmnum.

  IF sy-subrc = 0.
    " Already assigned — update
    UPDATE znotif_assign
      SET emp_id      = @p_empid,
          assigned_on = @sy-datum,
          status      = 'UPDATED'
      WHERE qmnum = @p_qmnum.

    IF sy-subrc = 0.
      MESSAGE 'Notification reassigned successfully.' TYPE 'S'.
    ELSE.
      MESSAGE 'Update failed.' TYPE 'E'.
    ENDIF.

  ELSE.
    " Not assigned — insert new entry
    wa_assign-qmnum       = p_qmnum.
    wa_assign-emp_id      = p_empid.
    wa_assign-assigned_on = sy-datum.
    wa_assign-status      = 'ASSIGNED'.

    INSERT znotif_assign FROM wa_assign.

    IF sy-subrc = 0.
      MESSAGE 'Notification assigned successfully.' TYPE 'S'.
    ELSE.
      MESSAGE 'Insert failed. Please check your data.' TYPE 'E'.
    ENDIF.
  ENDIF.
