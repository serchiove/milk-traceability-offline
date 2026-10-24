package pe.edu.utp.acopio.observability;

import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/** Evita registrar una recepción como confirmada si su transacción termina revirtiéndose. */
public final class EventosTransaccion {
  private EventosTransaccion() {}

  /**
   * Ejecuta un evento de diagnóstico después del commit o inmediatamente si no hay transacción.
   * No debe usarse como cola durable de eventos de negocio.
   *
   * @param evento escritura de diagnóstico, sin secretos ni datos personales
   */
  public static void despuesDeConfirmar(Runnable evento) {
    if (TransactionSynchronizationManager.isActualTransactionActive()
        && TransactionSynchronizationManager.isSynchronizationActive()) {
      TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
        @Override public void afterCommit() { evento.run(); }
      });
    } else {
      evento.run();
    }
  }
}
