package pe.edu.utp.acopio.controller;

import java.util.Map;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import pe.edu.utp.acopio.service.LoteService;

@RestControllerAdvice
public class ApiExceptionHandler {
  @ExceptionHandler(org.springframework.dao.DuplicateKeyException.class)
  ResponseEntity<?> duplicado() {
    return ResponseEntity.status(409)
        .body(
            Map.of(
                "mensaje",
                "Ya existe un registro con ese documento o placa, incluso si esta inactivo"));
  }

  @ExceptionHandler(pe.edu.utp.acopio.service.AdministracionCatalogoService.Conflicto.class)
  ResponseEntity<?> conflictoCatalogo(
      pe.edu.utp.acopio.service.AdministracionCatalogoService.Conflicto error) {
    return ResponseEntity.status(409).body(Map.of("mensaje", error.getMessage()));
  }

  @ExceptionHandler(pe.edu.utp.acopio.service.RecursoNoEncontradoException.class)
  ResponseEntity<?> noEncontrado() {
    return ResponseEntity.status(404).body(Map.of("mensaje", "Recurso no encontrado"));
  }

  @ExceptionHandler(pe.edu.utp.acopio.service.ConflictoAsignacionException.class)
  ResponseEntity<?> asignacionInvalida(
      pe.edu.utp.acopio.service.ConflictoAsignacionException error) {
    return ResponseEntity.status(409).body(Map.of("mensaje", error.getMessage()));
  }

  @ExceptionHandler(LoteService.ConflictoHuellaException.class)
  ResponseEntity<?> conflicto(LoteService.ConflictoHuellaException error) {
    return ResponseEntity.status(409).body(Map.of("mensaje", error.getMessage()));
  }

  @ExceptionHandler({
    MethodArgumentNotValidException.class,
    HttpMessageNotReadableException.class,
    DataIntegrityViolationException.class,
    IllegalArgumentException.class,
    org.springframework.web.method.annotation.MethodArgumentTypeMismatchException.class,
    org.springframework.web.bind.MissingServletRequestParameterException.class
  })
  ResponseEntity<?> datosInvalidos(Exception error) {
    // Hibernate wraps unique violations as DataIntegrityViolationException.
    for (Throwable cause = error; cause != null; cause = cause.getCause()) {
      if (cause instanceof java.sql.SQLException sql && "23505".equals(sql.getSQLState()))
        return duplicado();
    }
    return ResponseEntity.badRequest()
        .body(Map.of("mensaje", "Solicitud invalida: revisa campos, filtros y referencias"));
  }
}
