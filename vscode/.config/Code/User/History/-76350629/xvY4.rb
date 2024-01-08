module Constants
  module DiscountsDraft
    REASONS = {
      '0' => 'Sin Movimiento en el Mes: El trabajador no ha experimentado cambios o eventos relevantes durante el mes en cuestión.',
      '1' => 'Contratación a Plazo Indefinido: Se ha contratado a un trabajador bajo un contrato de duración indefinida.',
      '2' => 'Retiro: El trabajador ha dejado de trabajar en la empresa, ya sea por renuncia, despido u otro motivo de terminación de contrato.',
      '3' => 'Subsidios: El trabajador está recibiendo subsidios, posiblemente por licencia médica u otras circunstancias similares.',
      '4' => 'Permiso Sin Goce de Sueldos: El trabajador ha tomado un permiso, pero no recibirá sueldo durante ese período.',
      '5' => 'Incorporación en el Lugar de Trabajo: Nuevo ingreso al lugar de trabajo.',
      '6' => 'Accidentes del Trabajo: El trabajador ha experimentado un accidente laboral.',
      '7' => 'Contratación a Plazo Fijo: Se ha contratado a un trabajador bajo un contrato de duración específica.',
      '8' => 'Cambio de Contrato Plazo Fijo a Plazo Indefinido: El trabajador que estaba inicialmente bajo contrato a plazo fijo ha cambiado a un contrato a plazo indefinido.',
      '11' => 'Otros Movimientos (Ausentismos): Otros movimientos no especificados anteriormente, que pueden incluir ausencias por motivos diversos.',
      '12' => 'Reliquidación, Premio o Bono Posterior al Finiquito: Se realiza una reliquidación, premio o bono después de la finalización del contrato.',
      '13' => 'Suspensión Contrato Acto de Autoridad (Ley N°21.227): Suspensión del contrato de trabajo debido a acto de autoridad según la Ley N°21.227.',
      '14' => 'Suspensión Contrato por Pacto (Ley N°21.227): Suspensión del contrato de trabajo por pacto según la Ley N°21.227.',
      '15' => 'Reducción de Jornada (Ley N°21.227): Reducción de la jornada laboral según la Ley N°21.227.'
    }.freeze
  end
end
