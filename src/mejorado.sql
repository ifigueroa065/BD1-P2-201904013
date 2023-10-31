-- Crear la tabla Carrera
CREATE TABLE Carrera (
    CarreraID BIGINT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(255) UNIQUE
);

-- Crear la tabla Estudiante
CREATE TABLE Estudiante (
    Carnet BIGINT PRIMARY KEY,
    Nombres VARCHAR(255),
    Apellidos VARCHAR(255),
    FechaNacimiento DATE,
    Correo VARCHAR(255),
    Telefono BIGINT,
    Direccion VARCHAR(255),
    NumeroDPI BIGINT,
    CarreraID BIGINT,
    Creditos NUMERIC DEFAULT 0,
    FechaCreacion DATETIME DEFAULT NOW(),
    FOREIGN KEY (CarreraID) REFERENCES Carrera(CarreraID)
);

-- Crear la tabla Docente
CREATE TABLE Docente (
    RegistroSIIF BIGINT PRIMARY KEY,
    Nombres VARCHAR(255),
    Apellidos VARCHAR(255),
    FechaNacimiento DATE,
    Correo VARCHAR(255),
    Telefono BIGINT,
    Direccion VARCHAR(255),
    NumeroDPI BIGINT,
    FechaCreacion DATETIME DEFAULT NOW()
);

-- Crear la tabla Curso
CREATE TABLE Curso (
    Codigo BIGINT PRIMARY KEY,
    Nombre VARCHAR(255),
    CreditosNecesarios NUMERIC,
    CreditosOtorga NUMERIC,
    CarreraID BIGINT,
    EsObligatorio BOOLEAN,
    FOREIGN KEY (CarreraID) REFERENCES Carrera(CarreraID)
);

-- Crear la tabla CursoHabilitado
CREATE TABLE CursoHabilitado (
    CursoHabilitadoID BIGINT PRIMARY KEY AUTO_INCREMENT,
    CursoCodigo BIGINT,
    Ciclo VARCHAR(2),
    DocenteRegistroSIIF BIGINT,
    CupoMaximo BIGINT,
    Seccion CHAR(1),
    Anio BIGINT,
    CantidadEstudiantesAsignados NUMERIC DEFAULT 0,
    FOREIGN KEY (CursoCodigo) REFERENCES Curso(Codigo),
    FOREIGN KEY (DocenteRegistroSIIF) REFERENCES Docente(RegistroSIIF)
);

-- Crear la tabla HorarioCurso
CREATE TABLE HorarioCurso (
    HorarioCursoID BIGINT PRIMARY KEY AUTO_INCREMENT,
    CursoHabilitadoID BIGINT,
    DiaSemana NUMERIC CHECK (DiaSemana BETWEEN 1 AND 7),
    HoraInicio TIME,
    HoraFin TIME,
    FOREIGN KEY (CursoHabilitadoID) REFERENCES CursoHabilitado(CursoHabilitadoID)
);

-- Crear la tabla AsignacionCurso
CREATE TABLE AsignacionCurso (
    AsignacionCursoID BIGINT PRIMARY KEY AUTO_INCREMENT,
    Carnet BIGINT,
    CursoHabilitadoID BIGINT,
    FOREIGN KEY (Carnet) REFERENCES Estudiante(Carnet),
    FOREIGN KEY (CursoHabilitadoID) REFERENCES CursoHabilitado(CursoHabilitadoID)
);

-- Crear la tabla Notas
CREATE TABLE Notas (
    NotasID BIGINT PRIMARY KEY AUTO_INCREMENT,
    CursoCodigo BIGINT,
    Ciclo VARCHAR(2),
    Carnet BIGINT,
    Nota NUMERIC CHECK (Nota >= 0),
    Anio BIGINT,
    FOREIGN KEY (CursoCodigo) REFERENCES Curso(Codigo),
    FOREIGN KEY (Carnet) REFERENCES Estudiante(Carnet)
);

-- Crear la tabla Actas
CREATE TABLE Actas (
    ActasID BIGINT PRIMARY KEY AUTO_INCREMENT,
    CursoHabilitadoID BIGINT,
    FechaGeneracion DATETIME DEFAULT NOW(),
    FOREIGN KEY (CursoHabilitadoID) REFERENCES CursoHabilitado(CursoHabilitadoID)
);

-- Crear la tabla HistorialTransacciones
CREATE TABLE HistorialTransacciones (
    ID BIGINT PRIMARY KEY AUTO_INCREMENT,
    Fecha DATETIME,
    Descripcion TEXT,
    Tipo ENUM('INSERT', 'UPDATE', 'DELETE'),
    TablaAfectada VARCHAR(255)
);

-- Trigger para registrar inserciones en la tabla Estudiante
DELIMITER //
CREATE TRIGGER tr_estudiante_insert
AFTER INSERT ON Estudiante
FOR EACH ROW
BEGIN
    INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
    VALUES (NOW(), CONCAT('Se ha realizado una inserción en la tabla Estudiante. Carnet: ', NEW.Carnet), 'INSERT', 'Estudiante');
END;
//
DELIMITER ;



--FUNCION1


DELIMITER //

CREATE PROCEDURE registrarEstudiante(
  carnet_in BIGINT,
  nombres_in VARCHAR(255),
  apellidos_in VARCHAR(255),
  fecha_nacimiento_in VARCHAR(10), -- Cambiado a VARCHAR
  correo_in VARCHAR(255),
  telefono_in BIGINT,
  direccion_in VARCHAR(255),
  dpi_in BIGINT,
  carrera_id_in BIGINT
)
BEGIN
  DECLARE error_message VARCHAR(255);

  -- Validar que el correo tenga un formato válido
  IF correo_in NOT REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$' THEN
    SET error_message = 'El correo no tiene un formato válido';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
  END IF;

  -- Validar que el teléfono no tenga un código de área (omitir código de área)
  IF LENGTH(telefono_in) != 8 THEN
    SET error_message = 'El teléfono debe tener 8 dígitos sin código de área';
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
  END IF;

  -- Convertir la fecha al formato correcto (YYYY-MM-DD)
  SET fecha_nacimiento_in = STR_TO_DATE(fecha_nacimiento_in, '%d-%m-%Y');

  -- Insertar el estudiante en la tabla Estudiante
  INSERT INTO Estudiante (Carnet, Nombres, Apellidos, FechaNacimiento, Correo, Telefono, Direccion, NumeroDPI, CarreraID)
  VALUES (carnet_in, nombres_in, apellidos_in, fecha_nacimiento_in, correo_in, telefono_in, direccion_in, dpi_in, carrera_id_in);

  -- Registrar la fecha de creación en la tabla
  INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
  VALUES (NOW(), CONCAT('Se ha registrado un nuevo estudiante. Carnet: ', carnet_in), 'INSERT', 'Estudiante');
  
END;
//

DELIMITER ;

--FUNCION2
DELIMITER //

CREATE PROCEDURE crearCarrera(
  nombre_in VARCHAR(255)
)
BEGIN
  DECLARE error_occurred INT DEFAULT 0;

  -- Validar que el nombre solo contenga letras
  IF nombre_in NOT REGEXP '^[A-Za-z ]+$' THEN
    SET error_occurred = 1;
  END IF;

  IF error_occurred = 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El nombre de la carrera solo debe contener letras y espacios';
  ELSE
    -- Insertar la carrera en la tabla Carrera
    INSERT INTO Carrera (Nombre) VALUES (nombre_in);

    -- Registrar la fecha de creación en la tabla de historial de transacciones
    INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
    VALUES (NOW(), CONCAT('Se ha creado una nueva carrera: ', nombre_in), 'INSERT', 'Carrera');
  END IF;
  
END;
//

DELIMITER ;


--FUNCION3
DELIMITER //

CREATE PROCEDURE registrarDocente(
  nombres_in VARCHAR(255),
  apellidos_in VARCHAR(255),
  fecha_nacimiento_in VARCHAR(10), -- Cambiar el tipo a VARCHAR
  correo_in VARCHAR(255),
  telefono_in BIGINT,
  direccion_in VARCHAR(255),
  dpi_in BIGINT,
  registro_siif_in BIGINT
)
BEGIN
  DECLARE docente_existente INT;
  DECLARE error_message VARCHAR(255);
  DECLARE continue_execution INT DEFAULT 1;
  
  -- Validar que la fecha de nacimiento tenga un formato válido (dd-mm-yyyy)
  IF fecha_nacimiento_in NOT REGEXP '^[0-3][0-9]-[01][0-9]-[0-9]{4}$' THEN
    SET error_message = 'El formato de la fecha de nacimiento no es válido (dd-mm-yyyy)';
    SET continue_execution = 0;
  ELSE
    -- Formatear la fecha al formato 'yyyy-mm-dd' utilizando STR_TO_DATE
    SET fecha_nacimiento_in = STR_TO_DATE(fecha_nacimiento_in, '%d-%m-%Y');
  END IF;

  -- Validar que el correo tenga un formato válido
  IF correo_in NOT REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$' THEN
    SET error_message = 'El correo no tiene un formato válido';
    SET continue_execution = 0;
  END IF;

  -- Validar que el teléfono no tenga un código de área (omitir código de área)
  IF LENGTH(telefono_in) != 8 THEN
    SET error_message = 'El teléfono debe tener 8 dígitos sin código de área';
    SET continue_execution = 0;
  END IF;

  -- Verificar si el docente ya existe
  SELECT COUNT(*) INTO docente_existente FROM Docente WHERE NumeroDPI = dpi_in;
  IF docente_existente > 0 THEN
    SET error_message = 'Este docente ya ha sido registrado en el sistema';
    SET continue_execution = 0;
  END IF;

  -- Si no hay errores, insertar el docente
  IF continue_execution = 1 THEN
    INSERT INTO Docente (Nombres, Apellidos, FechaNacimiento, Correo, Telefono, Direccion, NumeroDPI, RegistroSIIF)
    VALUES (nombres_in, apellidos_in, fecha_nacimiento_in, correo_in, telefono_in, direccion_in, dpi_in, registro_siif_in);

    -- Registrar la fecha de creación en la tabla HistorialTransacciones
    INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
    VALUES (NOW(), CONCAT('Se ha registrado un nuevo docente. DPI: ', dpi_in), 'INSERT', 'Docente');
  ELSE
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
  END IF;
END;
//

DELIMITER ;

--FUNCION4
DELIMITER //

CREATE PROCEDURE crearCurso(
  codigo_in BIGINT,
  nombre_in VARCHAR(255),
  creditos_necesarios_in INT,
  creditos_otorga_in INT,
  carrera_in BIGINT,
  es_obligatorio_in BOOLEAN
)
BEGIN
  DECLARE valid_data INT DEFAULT 1;
  DECLARE error_message VARCHAR(255);

  -- Validar que los créditos necesarios y otorgados sean enteros positivos
  IF creditos_necesarios_in < 0 OR creditos_otorga_in < 0 THEN
    SET error_message = 'Los créditos necesarios y otorgados deben ser enteros positivos';
    SET valid_data = 0;
  END IF;

  -- Validar que la carrera pertenezca a un área común o tenga un identificador válido
  IF carrera_in < 0 THEN
    SET error_message = 'El identificador de la carrera no es válido';
    SET valid_data = 0;
  END IF;

  -- Si no hay errores, insertar el curso en la tabla Curso
  IF valid_data = 1 THEN
    -- Insertar el curso en la tabla Curso
    INSERT INTO Curso (Codigo, Nombre, CreditosNecesarios, CreditosOtorga, CarreraID, EsObligatorio)
    VALUES (codigo_in, nombre_in, creditos_necesarios_in, creditos_otorga_in, carrera_in, es_obligatorio_in);

    -- Registrar la fecha de creación en la tabla HistorialTransacciones
    INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
    VALUES (NOW(), CONCAT('Se ha creado un nuevo curso: ', nombre_in), 'INSERT', 'Curso');
  ELSE
    SELECT error_message AS MESSAGE;
  END IF;
END;
//

DELIMITER ;


--FUNCION5

DELIMITER //

CREATE PROCEDURE habilitarCurso(
  codigo_curso_in BIGINT,
  ciclo_in VARCHAR(2),
  docente_in BIGINT,
  cupo_maximo_in INT,
  seccion_in CHAR(1)
)
BEGIN
  DECLARE curso_existente INT;
  DECLARE valid_data INT DEFAULT 1;
  DECLARE error_message VARCHAR(255);

  -- Validar que el curso exista
  SELECT COUNT(*) INTO curso_existente FROM Curso WHERE Codigo = codigo_curso_in;
  IF curso_existente = 0 THEN
    SET error_message = 'El curso especificado no existe';
    SET valid_data = 0;
  END IF;

  -- Validar que el ciclo sea válido
  IF NOT (ciclo_in IN ('1S', '2S', 'VJ', 'VD')) THEN
    SET error_message = 'El ciclo especificado no es válido';
    SET valid_data = 0;
  END IF;

  -- Validar que el cupo máximo sea un número entero positivo
  IF cupo_maximo_in < 0 THEN
    SET error_message = 'El cupo máximo debe ser un número entero positivo';
    SET valid_data = 0;
  END IF;

  -- Validar que la sección sea una letra y guardarla en mayúscula
  IF LENGTH(seccion_in) <> 1 OR NOT seccion_in REGEXP '^[A-Za-z]$' THEN
    SET error_message = 'La sección debe ser una única letra en mayúscula';
    SET valid_data = 0;
  END IF;
  
  -- Si no hay errores, insertar la disponibilidad del curso en la tabla CursoHabilitado
  IF valid_data = 1 THEN
    INSERT INTO CursoHabilitado (CodigoCurso, Ciclo, Docente, CupoMaximo, Seccion, Anio, EstudiantesAsignados)
    VALUES (codigo_curso_in, ciclo_in, docente_in, cupo_maximo_in, UPPER(seccion_in), YEAR(NOW()), 0);

    -- Registrar la fecha de habilitación en la tabla HistorialTransacciones
    INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
    VALUES (NOW(), CONCAT('Se ha habilitado el curso (Código: ', codigo_curso_in, ', Ciclo: ', ciclo_in, ', Sección: ', UPPER(seccion_in), ')'), 'INSERT', 'CursoHabilitado');
  ELSE
    SELECT error_message AS MESSAGE;
  END IF;
END;
//

DELIMITER ;


--FUNCION6

DELIMITER //

CREATE PROCEDURE agregarHorario(
  id_curso_habilitado_in BIGINT,
  dia_in INT,
  horario_in VARCHAR(255)
)
BEGIN
  DECLARE curso_habilitado_existente INT;
  DECLARE valid_data INT DEFAULT 1;
  DECLARE error_message VARCHAR(255);

  -- Verificar si el curso habilitado existe
  SELECT COUNT(*) INTO curso_habilitado_existente FROM CursoHabilitado WHERE ID = id_curso_habilitado_in;
  IF curso_habilitado_existente = 0 THEN
    SET error_message = 'El curso habilitado con el ID especificado no existe';
    SET valid_data = 0;
  END IF;

  -- Validar que el día esté dentro del dominio [1,7]
  IF dia_in < 1 OR dia_in > 7 THEN
    SET error_message = 'El día debe estar dentro del dominio [1,7]';
    SET valid_data = 0;
  END IF;

  -- Validar que el horario tenga un formato válido
  IF horario_in NOT REGEXP '^[0-2]?[0-9]:[0-5][0-9]-[0-2]?[0-9]:[0-5][0-9]$' THEN
    SET error_message = 'El formato del horario no es válido';
    SET valid_data = 0;
  END IF;

  -- Comprobar si hubo errores
  IF valid_data = 0 THEN
    SELECT error_message AS MESSAGE;
  ELSE
    -- Insertar el horario en la tabla HorarioCursoHabilitado
    INSERT INTO HorarioCursoHabilitado (CursoHabilitadoID, Dia, Horario)
    VALUES (id_curso_habilitado_in, dia_in, horario_in);

    -- Registrar la fecha de creación en la tabla HistorialTransacciones
    INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
    VALUES (NOW(), CONCAT('Se ha agregado un horario al curso habilitado (ID: ', id_curso_habilitado_in, ')'), 'INSERT', 'HorarioCursoHabilitado');
  END IF;
END;
//

DELIMITER ;

--FUNCION7

DELIMITER //

CREATE PROCEDURE asignarCurso(
  codigo_curso_in BIGINT,
  ciclo_in VARCHAR(2),
  seccion_in CHAR(1),
  carnet_in BIGINT
)
BEGIN
  DECLARE curso_habilitado_id INT;
  DECLARE carnet_existente INT;
  DECLARE creditos_necesarios INT;
  DECLARE creditos_otorga INT;
  DECLARE cupo_actual INT;
  DECLARE cupo_maximo INT;
  DECLARE carrera_id INT;
  DECLARE error_message VARCHAR(255);

  -- Obtener el ID del curso habilitado correspondiente al año actual, ciclo y sección
  SELECT ID INTO curso_habilitado_id FROM CursoHabilitado
  WHERE CodigoCurso = codigo_curso_in
    AND Ciclo = ciclo_in
    AND Seccion = seccion_in
    AND Anio = YEAR(NOW());

  -- Verificar si el curso habilitado existe
  IF curso_habilitado_id IS NULL THEN
    SET error_message = 'No se encontró un curso habilitado para los parámetros especificados';
  ELSE
    -- Verificar si el carnet del estudiante existe
    SELECT COUNT(*) INTO carnet_existente FROM Estudiante WHERE Carnet = carnet_in;
    IF carnet_existente = 0 THEN
      SET error_message = 'El carnet del estudiante no existe';
    ELSE
      -- Obtener los créditos necesarios y otorgados del curso
      SELECT CreditosNecesarios, CreditosOtorga INTO creditos_necesarios, creditos_otorga FROM Curso WHERE Codigo = codigo_curso_in;

      -- Obtener la cantidad actual de estudiantes asignados al curso
      SELECT COUNT(*) INTO cupo_actual FROM AsignacionCurso WHERE CursoHabilitadoID = curso_habilitado_id;

      -- Obtener el cupo máximo del curso habilitado
      SELECT CupoMaximo INTO cupo_maximo FROM CursoHabilitado WHERE ID = curso_habilitado_id;

      -- Obtener la carrera del estudiante
      SELECT CarreraID INTO carrera_id FROM Estudiante WHERE Carnet = carnet_in;

      -- Validar que el estudiante no esté ya asignado al mismo curso o a otra sección
      IF EXISTS (SELECT 1 FROM AsignacionCurso ac
                 INNER JOIN CursoHabilitado ch ON ac.CursoHabilitadoID = ch.ID
                 WHERE ac.Carnet = carnet_in
                   AND ch.CodigoCurso = codigo_curso_in
                   AND ch.Ciclo = ciclo_in
                   AND ch.Seccion = seccion_in
                   AND ch.Anio = YEAR(NOW())) THEN
        SET error_message = 'El estudiante ya está asignado a este curso o a otra sección del mismo';
      ELSE
        -- Validar que el estudiante tenga los créditos necesarios y que el curso pertenezca a su carrera o área común
        IF creditos_otorga > 0 AND creditos_necesarios > 0 THEN
          IF (SELECT CreditosAprobados FROM Estudiante WHERE Carnet = carnet_in) < creditos_necesarios
          OR (SELECT CarreraID FROM Curso WHERE Codigo = codigo_curso_in) != 0
          AND (SELECT CarreraID FROM Curso WHERE Codigo = codigo_curso_in) != carrera_id THEN
            SET error_message = 'El estudiante no cumple con los requisitos del curso';
          ELSE
            -- Validar que la sección exista y no haya alcanzado el cupo máximo
            IF cupo_actual >= cupo_maximo THEN
              SET error_message = 'La sección del curso ha alcanzado el cupo máximo';
            ELSE
              -- Insertar la asignación del estudiante al curso
              INSERT INTO AsignacionCurso (Carnet, CursoHabilitadoID)
              VALUES (carnet_in, curso_habilitado_id);

              -- Incrementar la cantidad de estudiantes asignados al curso
              UPDATE CursoHabilitado
              SET EstudiantesAsignados = EstudiantesAsignados + 1
              WHERE ID = curso_habilitado_id;

              -- Registrar la fecha de asignación en la tabla HistorialTransacciones
              INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
              VALUES (NOW(), CONCAT('Se ha asignado al estudiante (Carnet: ', carnet_in, ') al curso habilitado (ID: ', curso_habilitado_id, ')'), 'INSERT', 'AsignacionCurso');
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;
  END IF;

  -- Si hay un mensaje de error, lanzar la excepción
  IF error_message IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
  END IF;
END;
//

DELIMITER ;

--FUNCION8

DELIMITER //

CREATE PROCEDURE desasignarCurso(
  codigo_curso_in BIGINT,
  ciclo_in VARCHAR(2),
  seccion_in CHAR(1),
  carnet_in BIGINT
)
BEGIN
  DECLARE curso_habilitado_id INT;
  DECLARE carnet_existente INT;
  DECLARE estudiante_asignado INT;
  DECLARE cupo_actual INT;
  DECLARE error_message VARCHAR(255);

  -- Obtener el ID del curso habilitado correspondiente al año actual, ciclo y sección
  SELECT ID INTO curso_habilitado_id FROM CursoHabilitado
  WHERE CodigoCurso = codigo_curso_in
    AND Ciclo = ciclo_in
    AND Seccion = seccion_in
    AND Anio = YEAR(NOW());

  -- Verificar si el curso habilitado existe
  IF curso_habilitado_id IS NULL THEN
    SET error_message = 'No se encontró un curso habilitado para los parámetros especificados';
  ELSE
    -- Verificar si el carnet del estudiante existe
    SELECT COUNT(*) INTO carnet_existente FROM Estudiante WHERE Carnet = carnet_in;
    IF carnet_existente = 0 THEN
      SET error_message = 'El carnet del estudiante no existe';
    ELSE
      -- Verificar si el estudiante ya está asignado al curso
      SELECT COUNT(*) INTO estudiante_asignado FROM AsignacionCurso WHERE Carnet = carnet_in AND CursoHabilitadoID = curso_habilitado_id;
      IF estudiante_asignado = 0 THEN
        SET error_message = 'El estudiante no está asignado a este curso o sección';
      ELSE
        -- Obtener la cantidad actual de estudiantes asignados al curso
        SELECT COUNT(*) INTO cupo_actual FROM AsignacionCurso WHERE CursoHabilitadoID = curso_habilitado_id;

        -- Desasignar al estudiante del curso
        DELETE FROM AsignacionCurso
        WHERE Carnet = carnet_in
          AND CursoHabilitadoID = curso_habilitado_id;

        -- Disminuir la cantidad de estudiantes asignados al curso
        UPDATE CursoHabilitado
        SET EstudiantesAsignados = EstudiantesAsignados - 1
        WHERE ID = curso_habilitado_id;

        -- Registrar la fecha de desasignación en la tabla HistorialTransacciones
        INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
        VALUES (NOW(), CONCAT('Se ha desasignado al estudiante (Carnet: ', carnet_in, ') del curso habilitado (ID: ', curso_habilitado_id, ')'), 'DELETE', 'AsignacionCurso');
      END IF;
    END IF;
  END IF;

  -- Si hay un mensaje de error, lanzar la excepción
  IF error_message IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
  END IF;
END;
//

DELIMITER ;

--FUNCION9


DELIMITER //

CREATE PROCEDURE ingresarNota(
  codigo_curso_in BIGINT,
  ciclo_in VARCHAR(2),
  seccion_in CHAR(1),
  carnet_in BIGINT,
  nota_in DECIMAL(5, 2)
)
BEGIN
  DECLARE curso_habilitado_id INT;
  DECLARE carnet_existente INT;
  DECLARE creditos_otorga INT;
  DECLARE error_message VARCHAR(255);

  -- Obtener el ID del curso habilitado correspondiente al año actual, ciclo y sección
  SELECT ID INTO curso_habilitado_id FROM CursoHabilitado
  WHERE CodigoCurso = codigo_curso_in
    AND Ciclo = ciclo_in
    AND Seccion = seccion_in
    AND Anio = YEAR(NOW());

  -- Verificar si el curso habilitado existe
  IF curso_habilitado_id IS NULL THEN
    SET error_message = 'No se encontró un curso habilitado para los parámetros especificados';
  ELSE
    -- Verificar si el carnet del estudiante existe
    SELECT COUNT(*) INTO carnet_existente FROM Estudiante WHERE Carnet = carnet_in;
    IF carnet_existente = 0 THEN
      SET error_message = 'El carnet del estudiante no existe';
    ELSE
      -- Validar que la nota sea positiva
      IF nota_in < 0 THEN
        SET error_message = 'La nota debe ser positiva';
      ELSE
        -- Obtener los créditos otorgados por el curso
        SELECT CreditosOtorga INTO creditos_otorga FROM Curso WHERE Codigo = codigo_curso_in;

        -- Ingresar la nota en la tabla Notas
        INSERT INTO Notas (Carnet, CursoHabilitadoID, Nota)
        VALUES (carnet_in, curso_habilitado_id, ROUND(nota_in));

        -- Actualizar los créditos aprobados del estudiante si la nota es >= 61
        IF nota_in >= 61 THEN
          UPDATE Estudiante
          SET CreditosAprobados = CreditosAprobados + creditos_otorga
          WHERE Carnet = carnet_in;
        END IF;

        -- Registrar la fecha de ingreso de la nota en la tabla HistorialTransacciones
        INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
        VALUES (NOW(), CONCAT('Se ha ingresado una nota (Carnet: ', carnet_in, ') al curso habilitado (ID: ', curso_habilitado_id, ')'), 'INSERT', 'Notas');
      END IF;
    END IF;
  END IF;

  -- Si hay un mensaje de error, lanzar la excepción
  IF error_message IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
  END IF;
END;
//

DELIMITER ;

--FUNCION10

DELIMITER //

CREATE PROCEDURE generarActa(
  codigo_curso_in BIGINT,
  ciclo_in VARCHAR(2),
  seccion_in CHAR(1)
)
BEGIN
  DECLARE curso_habilitado_id INT;
  DECLARE total_estudiantes INT;
  DECLARE total_notas_ingresadas INT;
  DECLARE error_message VARCHAR(255);

  -- Obtener el ID del curso habilitado correspondiente al año actual, ciclo y sección
  SELECT ID INTO curso_habilitado_id FROM CursoHabilitado
  WHERE CodigoCurso = codigo_curso_in
    AND Ciclo = ciclo_in
    AND Seccion = seccion_in
    AND Anio = YEAR(NOW());

  -- Verificar si el curso habilitado existe
  IF curso_habilitado_id IS NULL THEN
    SET error_message = 'No se encontró un curso habilitado para los parámetros especificados';
  ELSE
    -- Contar el número total de estudiantes asignados al curso
    SELECT COUNT(*) INTO total_estudiantes FROM AsignacionCurso WHERE CursoHabilitadoID = curso_habilitado_id;

    -- Contar el número total de notas ingresadas para el curso
    SELECT COUNT(*) INTO total_notas_ingresadas FROM Notas WHERE CursoHabilitadoID = curso_habilitado_id;

    -- Verificar si todas las notas han sido ingresadas
    IF total_notas_ingresadas < total_estudiantes THEN
      SET error_message = 'No se han ingresado las notas de todos los estudiantes asignados al curso';
    ELSE
      -- Insertar el acta en la tabla Acta
      INSERT INTO Acta (CursoHabilitadoID, FechaGeneracion)
      VALUES (curso_habilitado_id, NOW());

      -- Registrar la fecha y hora de generación del acta en la tabla HistorialTransacciones
      INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
      VALUES (NOW(), CONCAT('Se ha generado un acta para el curso habilitado (ID: ', curso_habilitado_id, ')'), 'INSERT', 'Acta');
    END IF;
  END IF;

  -- Si hay un mensaje de error, lanzar la excepción
  IF error_message IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_message;
  END IF;
END;
//

DELIMITER ;



--PROCE1

DELIMITER //

CREATE PROCEDURE consultarPensum(
  codigo_carrera_in BIGINT
)
BEGIN
  -- Declarar una variable para el tipo de curso (área común o área profesional)
  DECLARE tipo_curso VARCHAR(255);
  
  -- Crear una tabla temporal para almacenar los resultados
  CREATE TEMPORARY TABLE TempPensum (
    CodigoCurso BIGINT,
    NombreCurso VARCHAR(255),
    EsObligatorio CHAR(2),
    CreditosNecesarios INT
  );
  
  -- Obtener los cursos de área común
  INSERT INTO TempPensum
  SELECT Codigo, Nombre, 'No', CreditosNecesarios
  FROM Curso
  WHERE CarreraID = 0;
  
  -- Obtener los cursos de área profesional
  INSERT INTO TempPensum
  SELECT Codigo, Nombre, 'Sí', CreditosNecesarios
  FROM Curso
  WHERE CarreraID = codigo_carrera_in;
  
  -- Seleccionar y mostrar los resultados
  SELECT * FROM TempPensum;
  
  -- Eliminar la tabla temporal
  DROP TEMPORARY TABLE TempPensum;
END;
//

DELIMITER ;


--PROCE2

DELIMITER //
CREATE PROCEDURE consultarEstudiante(IN carnetParam BIGINT)
BEGIN
    DECLARE carnetValue BIGINT;
    DECLARE nombreCompletoValue VARCHAR(255);
    DECLARE fechaNacimientoValue DATE;
    DECLARE correoValue VARCHAR(255);
    DECLARE telefonoValue BIGINT;
    DECLARE direccionValue VARCHAR(255);
    DECLARE numeroDPIValue BIGINT;
    DECLARE carreraNombre VARCHAR(255);
    DECLARE creditosValue NUMERIC;

    -- Verificar si el estudiante existe
    SELECT Carnet, CONCAT(Nombres, ' ', Apellidos), FechaNacimiento, Correo, Telefono, Direccion, NumeroDPI, Carrera.Nombre, Creditos
    INTO carnetValue, nombreCompletoValue, fechaNacimientoValue, correoValue, telefonoValue, direccionValue, numeroDPIValue, carreraNombre, creditosValue
    FROM Estudiante
    LEFT JOIN Carrera ON Estudiante.CarreraID = Carrera.CarreraID
    WHERE Carnet = carnetParam;

    -- Comprobar si se encontró el estudiante
    IF carnetValue IS NOT NULL THEN
        -- Devolver los datos del estudiante
        SELECT carnetValue AS Carnet, nombreCompletoValue AS NombreCompleto, fechaNacimientoValue AS FechaNacimiento, correoValue AS Correo, telefonoValue AS Telefono, direccionValue AS Direccion, numeroDPIValue AS NumeroDPI, carreraNombre AS Carrera, creditosValue AS Creditos;
    ELSE
        -- Mostrar un mensaje de error si el estudiante no existe
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estudiante no encontrado';
    END IF;
END //
DELIMITER ;


--PROCE3


DELIMITER //

CREATE PROCEDURE consultarDocente(
  registro_siif_in BIGINT
)
BEGIN
  DECLARE registro_siif_existente INT;

  -- Verificar si el registro SIIF del docente existe
  SELECT COUNT(*) INTO registro_siif_existente FROM Docente WHERE RegistroSIIF = registro_siif_in;
  
  -- Validar si el registro SIIF existe
  IF registro_siif_existente = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El registro SIIF del docente no existe';
  ELSE
    -- Consultar la información del docente
    SELECT
      RegistroSIIF,
      CONCAT(Nombres, ' ', Apellidos) AS NombreCompleto,
      FechaNacimiento,
      Correo,
      Telefono,
      Direccion,
      NumeroDPI
    FROM Docente
    WHERE RegistroSIIF = registro_siif_in;
  END IF;
END;
//

DELIMITER ;


--PROCE4

DELIMITER //

CREATE PROCEDURE consultarAsignados(
  codigo_curso_in BIGINT,
  ciclo_in VARCHAR(2),
  anio_in BIGINT,
  seccion_in CHAR(1)
)
BEGIN
  DECLARE curso_habilitado_id INT;
  DECLARE total_registros INT;

  -- Obtener el ID del curso habilitado correspondiente al código de curso, ciclo, año y sección
  SELECT ID INTO curso_habilitado_id FROM CursoHabilitado
  WHERE CodigoCurso = codigo_curso_in
    AND Ciclo = ciclo_in
    AND Anio = anio_in
    AND Seccion = seccion_in;
  
  -- Verificar si el curso habilitado existe
  IF curso_habilitado_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se encontró un curso habilitado para los parámetros especificados';
  ELSE
    -- Contar el número de estudiantes asignados al curso habilitado
    SELECT COUNT(*) INTO total_registros FROM AsignacionCurso WHERE CursoHabilitadoID = curso_habilitado_id;
    
    -- Validar si hay estudiantes asignados
    IF total_registros = 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay estudiantes asignados a este curso y sección';
    ELSE
      -- Consultar la lista de estudiantes asignados al curso
      SELECT
        Estudiante.Carnet,
        CONCAT(Estudiante.Nombres, ' ', Estudiante.Apellidos) AS NombreCompleto,
        Estudiante.CreditosAprobados AS CreditosPosee
      FROM Estudiante
      INNER JOIN AsignacionCurso ON Estudiante.Carnet = AsignacionCurso.Carnet
      WHERE AsignacionCurso.CursoHabilitadoID = curso_habilitado_id;
    END IF;
  END IF;
END;
//

DELIMITER ;


--PROCE5

DELIMITER //

CREATE PROCEDURE consultarAprobacion(
  codigo_curso_in BIGINT,
  ciclo_in VARCHAR(2),
  anio_in BIGINT,
  seccion_in CHAR(1)
)
BEGIN
  DECLARE curso_habilitado_id INT;
  
  -- Obtener el ID del curso habilitado correspondiente al código de curso, ciclo, año y sección
  SELECT ID INTO curso_habilitado_id FROM CursoHabilitado
  WHERE CodigoCurso = codigo_curso_in
    AND Ciclo = ciclo_in
    AND Anio = anio_in
    AND Seccion = seccion_in;
  
  -- Verificar si el curso habilitado existe
  IF curso_habilitado_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se encontró un curso habilitado para los parámetros especificados';
  ELSE
    -- Consultar el listado de aprobaciones y reprobaciones
    SELECT
      codigo_curso_in AS "Código de Curso",
      Estudiante.Carnet,
      CONCAT(Estudiante.Nombres, ' ', Estudiante.Apellidos) AS "Nombre Completo",
      CASE
        WHEN Notas.Nota >= 61 THEN 'APROBADO'
        ELSE 'DESAPROBADO'
      END AS "Resultado"
    FROM Estudiante
    LEFT JOIN Notas ON Estudiante.Carnet = Notas.Carnet
    WHERE Notas.CursoHabilitadoID = curso_habilitado_id;
  END IF;
END;
//

DELIMITER ;


--PROCE6

DELIMITER //

CREATE PROCEDURE consultarActas(
  codigo_curso_in BIGINT
)
BEGIN
  -- Verificar si el curso existe
  DECLARE curso_existente INT;
  SELECT COUNT(*) INTO curso_existente FROM Curso WHERE Codigo = codigo_curso_in;
  IF curso_existente = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El código de curso no existe';
  ELSE
    -- Consultar el listado de actas
    SELECT
      codigo_curso_in AS "Código de Curso",
      CursoHabilitado.Seccion,
      CASE
        WHEN CursoHabilitado.Ciclo = '1S' THEN 'PRIMER SEMESTRE'
        WHEN CursoHabilitado.Ciclo = '2S' THEN 'SEGUNDO SEMESTRE'
        WHEN CursoHabilitado.Ciclo = 'VJ' THEN 'VACACIONES DE JUNIO'
        WHEN CursoHabilitado.Ciclo = 'VD' THEN 'VACACIONES DE DICIEMBRE'
      END AS "Ciclo",
      CursoHabilitado.Anio AS "Año",
      (SELECT COUNT(*) FROM Notas WHERE CursoHabilitadoID = CursoHabilitado.ID) AS "Cantidad de Estudiantes",
      Acta.FechaGeneracion AS "Fecha y Hora de Generado"
    FROM CursoHabilitado
    INNER JOIN Curso ON CursoHabilitado.CodigoCurso = Curso.Codigo
    LEFT JOIN Acta ON CursoHabilitado.ID = Acta.CursoHabilitadoID
    WHERE Curso.Codigo = codigo_curso_in
    ORDER BY Acta.FechaGeneracion;
  END IF;
END;
//

DELIMITER ;


--PROCE7

DELIMITER //

CREATE PROCEDURE consultarDesasignacion(
  codigo_curso_in BIGINT,
  ciclo_in VARCHAR(2),
  anio_in BIGINT,
  seccion_in CHAR(1)
)
BEGIN
  -- Verificar si el curso existe
  SET @curso_existente = (SELECT COUNT(*) FROM Curso WHERE Codigo = codigo_curso_in);
  
  -- Validar si el curso existe
  IF @curso_existente = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El código de curso no existe';
  ELSE
    -- Obtener el ID del curso habilitado correspondiente al código de curso, ciclo, año y sección
    SET @curso_habilitado_id = (SELECT ID FROM CursoHabilitado
      WHERE CodigoCurso = codigo_curso_in
      AND Ciclo = ciclo_in
      AND Anio = anio_in
      AND Seccion = seccion_in);
  
    -- Validar si el curso habilitado existe
    IF @curso_habilitado_id IS NULL THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se encontró un curso habilitado para los parámetros especificados';
    ELSE
      -- Calcular la cantidad de estudiantes que llevaron el curso
      SET @cantidad_estudiantes_curso = (SELECT COUNT(*) FROM AsignacionCurso
      WHERE CursoHabilitadoID = @curso_habilitado_id);
    
      -- Calcular la cantidad de estudiantes que se desasignaron
      SET @cantidad_desasignados = (SELECT COUNT(*) FROM DesasignacionCurso
      WHERE CursoHabilitadoID = @curso_habilitado_id);
    
      -- Calcular el porcentaje de desasignación
      IF @cantidad_estudiantes_curso > 0 THEN
        SET @porcentaje_desasignacion = (@cantidad_desasignados / @cantidad_estudiantes_curso) * 100;
      ELSE
        SET @porcentaje_desasignacion = 0;
      END IF;
    
      -- Consultar y mostrar los resultados
      SELECT
        codigo_curso_in AS "Código de Curso",
        seccion_in AS "Sección",
        CASE
          WHEN ciclo_in = '1S' THEN 'PRIMER SEMESTRE'
          WHEN ciclo_in = '2S' THEN 'SEGUNDO SEMESTRE'
          WHEN ciclo_in = 'VJ' THEN 'VACACIONES DE JUNIO'
          WHEN ciclo_in = 'VD' THEN 'VACACIONES DE DICIEMBRE'
        END AS "Ciclo",
        anio_in AS "Año",
        @cantidad_estudiantes_curso AS "Cantidad de Estudiantes que llevaron el curso",
        @cantidad_desasignados AS "Cantidad de Estudiantes que se desasignaron",
        @porcentaje_desasignacion AS "Porcentaje de Desasignación";
    END IF;
  END IF;
END;
//

DELIMITER ;


