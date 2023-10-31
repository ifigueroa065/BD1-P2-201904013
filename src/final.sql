-- Crear la tabla Persona
CREATE TABLE Persona (
    ID BIGINT AUTO_INCREMENT PRIMARY KEY,
    Nombres VARCHAR(255),
    Apellidos VARCHAR(255),
    FechaNacimiento DATE,
    Correo VARCHAR(255),
    Telefono BIGINT,
    Direccion VARCHAR(255),
    NumeroDPI BIGINT
);

-- Crear la tabla Carrera
CREATE TABLE Carrera (
    CarreraID BIGINT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(255) UNIQUE
);

-- Crear la tabla Estudiante
CREATE TABLE Estudiante (
    Carnet BIGINT PRIMARY KEY,
    PersonaID BIGINT,
    CarreraID BIGINT,
    Creditos NUMERIC DEFAULT 0,
    FechaCreacion DATETIME DEFAULT NOW(),
    FOREIGN KEY (PersonaID) REFERENCES Persona(ID),
    FOREIGN KEY (CarreraID) REFERENCES Carrera(CarreraID)
);

-- Crear la tabla Docente
CREATE TABLE Docente (
    RegistroSIIF BIGINT PRIMARY KEY,
    PersonaID BIGINT,
    FechaCreacion DATETIME DEFAULT NOW(),
    FOREIGN KEY (PersonaID) REFERENCES Persona(ID)
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


--TRIGGERS UTILIZADOS
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


--IMPLEMENTANDO FUNCIONES

--FUNCION1
DELIMITER //

CREATE PROCEDURE registrarEstudiante(
    IN p_Carnet BIGINT,
    IN p_Nombres VARCHAR(255),
    IN p_Apellidos VARCHAR(255),
    IN p_FechaNacimiento VARCHAR(10), -- Formato 'DD-MM-YYYY'
    IN p_Correo VARCHAR(255),
    IN p_Telefono BIGINT,
    IN p_Direccion VARCHAR(255),
    IN p_NumeroDPI BIGINT,
    IN p_CarreraID BIGINT
)
BEGIN
    DECLARE v_Error VARCHAR(255);
    DECLARE v_PersonaID BIGINT;

    -- Validar el formato del correo
    IF p_Correo NOT REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$' THEN
        SET v_Error = 'El formato del correo no es válido';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el teléfono no tenga un código de área (omitir código de área)
    IF LENGTH(p_Telefono) != 8 THEN
        SET v_Error = 'El teléfono debe tener 8 dígitos sin código de área';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Convertir la fecha al formato correcto (YYYY-MM-DD)
    SET p_FechaNacimiento = STR_TO_DATE(p_FechaNacimiento, '%d-%m-%Y');

    -- Verificar si el estudiante ya existe
    IF EXISTS (SELECT 1 FROM Estudiante WHERE Carnet = p_Carnet) THEN
        SET v_Error = 'El estudiante ya existe en la base de datos';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    ELSE
        -- Obtener el ID de la persona si ya existe
        SELECT ID INTO v_PersonaID FROM Persona WHERE Nombres = p_Nombres AND Apellidos = p_Apellidos AND FechaNacimiento = p_FechaNacimiento AND Correo = p_Correo AND Telefono = p_Telefono AND Direccion = p_Direccion AND NumeroDPI = p_NumeroDPI LIMIT 1;
        
        -- Si no existe la persona, insertarla
        IF v_PersonaID IS NULL THEN
            INSERT INTO Persona (Nombres, Apellidos, FechaNacimiento, Correo, Telefono, Direccion, NumeroDPI)
            VALUES (p_Nombres, p_Apellidos, p_FechaNacimiento, p_Correo, p_Telefono, p_Direccion, p_NumeroDPI);
            
            -- Obtener el ID de la persona recién insertada
            SET v_PersonaID = LAST_INSERT_ID();
        END IF;
        
        -- Insertar el estudiante en la tabla Estudiante
        INSERT INTO Estudiante (Carnet, PersonaID, CarreraID, Creditos, FechaCreacion)
        VALUES (p_Carnet, v_PersonaID, p_CarreraID, 0, NOW());
        
        -- Registrar la fecha de creación en el historial de transacciones
        INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
        VALUES (NOW(), CONCAT('Se ha registrado un nuevo estudiante. Carnet: ', p_Carnet), 'INSERT', 'Estudiante');
    END IF;
END;
//

DELIMITER ;


--FUNCION2

DELIMITER //

CREATE PROCEDURE crearCarrera(
    IN p_Nombre VARCHAR(255)
)
BEGIN
    -- Validar que el nombre solo contenga letras
    IF p_Nombre NOT REGEXP '^[A-Za-z ]+$' THEN
        SELECT 'El nombre de la carrera solo debe contener letras' AS Error;
    ELSE
        -- Insertar la carrera en la tabla Carrera
        INSERT INTO Carrera (Nombre)
        VALUES (p_Nombre);
    END IF;
END;
//

DELIMITER ;


--FUNCION3

DELIMITER //

CREATE PROCEDURE registrarDocente(
    IN p_Nombres VARCHAR(255),
    IN p_Apellidos VARCHAR(255),
    IN p_FechaNacimiento VARCHAR(10), -- Cambiado a VARCHAR
    IN p_Correo VARCHAR(255),
    IN p_Telefono BIGINT,
    IN p_Direccion VARCHAR(255),
    IN p_NumeroDPI BIGINT,
    IN p_RegistroSIIF BIGINT
)
BEGIN
    -- Validar que el docente no existe previamente
    DECLARE v_PersonaID BIGINT;
    SET v_PersonaID = (SELECT ID FROM Persona WHERE Nombres = p_Nombres AND Apellidos = p_Apellidos AND FechaNacimiento = STR_TO_DATE(p_FechaNacimiento, '%d-%m-%Y') AND Correo = p_Correo LIMIT 1);
    
    IF v_PersonaID IS NOT NULL THEN
        SELECT 'El docente ya existe en la base de datos' AS Error;
    ELSE
        -- Validar el formato del correo
        IF p_Correo NOT REGEXP '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$' THEN
            SELECT 'El formato del correo no es válido' AS Error;
        ELSE
            -- Convertir la fecha al formato correcto (YYYY-MM-DD)
            SET p_FechaNacimiento = STR_TO_DATE(p_FechaNacimiento, '%d-%m-%Y');

            -- Insertar datos del docente en la tabla Persona
            INSERT INTO Persona (Nombres, Apellidos, FechaNacimiento, Correo, Telefono, Direccion, NumeroDPI)
            VALUES (p_Nombres, p_Apellidos, p_FechaNacimiento, p_Correo, p_Telefono, p_Direccion, p_NumeroDPI);

            -- Obtener el ID de la persona recién insertada
            SET v_PersonaID = LAST_INSERT_ID();

            -- Insertar datos del docente en la tabla Docente
            INSERT INTO Docente (RegistroSIIF, PersonaID, FechaCreacion)
            VALUES (p_RegistroSIIF, v_PersonaID, NOW());

            -- Registrar la inserción en el historial de transacciones
            INSERT INTO HistorialTransacciones (Fecha, Descripcion, Tipo, TablaAfectada)
            VALUES (NOW(), CONCAT('Se ha registrado un docente con Registro SIIF: ', p_RegistroSIIF), 'INSERT', 'Docente');
        END IF;
    END IF;
END;
//

DELIMITER ;


--FUNCION 4 

DELIMITER //

CREATE PROCEDURE crearCurso(
    IN p_Codigo BIGINT,
    IN p_Nombre VARCHAR(255),
    IN p_CreditosNecesarios NUMERIC,
    IN p_CreditosOtorga NUMERIC,
    IN p_CarreraID BIGINT,
    IN p_EsObligatorio BOOLEAN
)
BEGIN
    DECLARE v_Error VARCHAR(255);

    -- Validar que el código del curso no exista previamente
    IF EXISTS (SELECT 1 FROM Curso WHERE Codigo = p_Codigo) THEN
        SET v_Error = 'El curso con el código especificado ya existe en la base de datos';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    ELSE
        -- Validar que los créditos necesarios sean un entero no negativo
        IF p_CreditosNecesarios < 0 OR p_CreditosNecesarios != ROUND(p_CreditosNecesarios) THEN
            SET v_Error = 'Los créditos necesarios deben ser un entero no negativo';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
        END IF;

        -- Validar que los créditos que otorga sean un entero no negativo
        IF p_CreditosOtorga < 0 OR p_CreditosOtorga != ROUND(p_CreditosOtorga) THEN
            SET v_Error = 'Los créditos que otorga deben ser un entero no negativo';
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
        END IF;

        -- Insertar el curso en la tabla Curso
        INSERT INTO Curso (Codigo, Nombre, CreditosNecesarios, CreditosOtorga, CarreraID, EsObligatorio)
        VALUES (p_Codigo, p_Nombre, p_CreditosNecesarios, p_CreditosOtorga, p_CarreraID, p_EsObligatorio);
    END IF;
END;
//

DELIMITER ;


--FUNCION 5

DELIMITER //

CREATE PROCEDURE habilitarCurso(
    IN p_CursoCodigo BIGINT,
    IN p_Ciclo VARCHAR(2),
    IN p_DocenteRegistroSIIF BIGINT,
    IN p_CupoMaximo BIGINT,
    IN p_Seccion CHAR(1)
)
BEGIN
    DECLARE v_Error VARCHAR(255);
    
    -- Validar que el curso exista
    IF NOT EXISTS (SELECT 1 FROM Curso WHERE Codigo = p_CursoCodigo) THEN
        SET v_Error = 'El curso especificado no existe en la base de datos';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el ciclo sea válido ('1S', '2S', 'VJ', 'VD')
    IF NOT (p_Ciclo = '1S' OR p_Ciclo = '2S' OR p_Ciclo = 'VJ' OR p_Ciclo = 'VD') THEN
        SET v_Error = 'El ciclo no es válido. Debe ser "1S", "2S", "VJ" o "VD".';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el docente exista
    IF NOT EXISTS (SELECT 1 FROM Docente WHERE RegistroSIIF = p_DocenteRegistroSIIF) THEN
        SET v_Error = 'El docente especificado no existe en la base de datos';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el cupo máximo sea un número entero positivo
    IF p_CupoMaximo < 0 OR p_CupoMaximo != ROUND(p_CupoMaximo) THEN
        SET v_Error = 'El cupo máximo debe ser un número entero positivo';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Convertir la sección a mayúscula
    SET p_Seccion = UPPER(p_Seccion);

    -- Insertar el curso habilitado en la tabla CursoHabilitado
    INSERT INTO CursoHabilitado (CursoCodigo, Ciclo, DocenteRegistroSIIF, CupoMaximo, Seccion, Anio, CantidadEstudiantesAsignados)
    VALUES (p_CursoCodigo, p_Ciclo, p_DocenteRegistroSIIF, p_CupoMaximo, p_Seccion, YEAR(NOW()), 0);
END;
//

DELIMITER ;


--FUNCION6


DELIMITER //

CREATE PROCEDURE agregarHorario(
    IN p_CursoHabilitadoID BIGINT,
    IN p_DiaSemana NUMERIC,
    IN p_HoraInicio TIME,
    IN p_HoraFin TIME
)
BEGIN
    DECLARE v_Error VARCHAR(255);
    
    -- Verificar si el curso habilitado existe
    IF NOT EXISTS (SELECT 1 FROM CursoHabilitado WHERE CursoHabilitadoID = p_CursoHabilitadoID) THEN
        SET v_Error = 'El curso habilitado especificado no existe en la base de datos';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el día esté dentro del dominio [1,7]
    IF p_DiaSemana < 1 OR p_DiaSemana > 7 THEN
        SET v_Error = 'El día de la semana debe estar dentro del rango [1,7].';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que la hora de inicio sea menor que la hora de fin
    IF p_HoraInicio >= p_HoraFin THEN
        SET v_Error = 'La hora de inicio debe ser menor que la hora de fin.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Insertar el horario del curso habilitado en la tabla HorarioCurso
    INSERT INTO HorarioCurso (CursoHabilitadoID, DiaSemana, HoraInicio, HoraFin)
    VALUES (p_CursoHabilitadoID, p_DiaSemana, p_HoraInicio, p_HoraFin);
END;
//

DELIMITER ;


--FUNCION7

DELIMITER //

CREATE PROCEDURE asignarCurso(
    IN p_CursoCodigo BIGINT,
    IN p_Ciclo VARCHAR(2),
    IN p_Seccion CHAR(1),
    IN p_Carnet BIGINT
)
BEGIN
    DECLARE v_Error VARCHAR(255);
    DECLARE v_CursoHabilitadoID BIGINT;
    DECLARE v_CreditosNecesarios NUMERIC;
    DECLARE v_CreditosActuales NUMERIC;
    DECLARE v_CupoMaximo BIGINT;
    DECLARE v_CantidadEstudiantesAsignados NUMERIC;

    -- Verificar si el carnet del estudiante existe
    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE Carnet = p_Carnet) THEN
        SET v_Error = 'El carnet del estudiante no existe en la base de datos';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el curso habilitado existe
    SET v_CursoHabilitadoID = (SELECT CursoHabilitadoID FROM CursoHabilitado WHERE CursoCodigo = p_CursoCodigo AND Ciclo = p_Ciclo AND Seccion = p_Seccion AND YEAR(NOW()) = YEAR(CursoHabilitado.FechaCreacion) LIMIT 1);

    IF v_CursoHabilitadoID IS NULL THEN
        SET v_Error = 'El curso habilitado especificado no existe en la base de datos para el año actual, ciclo y sección.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el estudiante no esté asignado al mismo curso y sección
    IF EXISTS (SELECT 1 FROM AsignacionCurso WHERE Carnet = p_Carnet AND CursoHabilitadoID = v_CursoHabilitadoID) THEN
        SET v_Error = 'El estudiante ya está asignado al mismo curso y sección.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el estudiante tenga los créditos necesarios
    SET v_CreditosNecesarios = (SELECT CreditosNecesarios FROM Curso WHERE Codigo = p_CursoCodigo LIMIT 1);

    SET v_CreditosActuales = (SELECT Creditos FROM Estudiante WHERE Carnet = p_Carnet LIMIT 1);

    IF v_CreditosActuales < v_CreditosNecesarios THEN
        SET v_Error = 'El estudiante no tiene los créditos necesarios para inscribirse en este curso.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el cupo máximo no se haya alcanzado
    SET v_CupoMaximo = (SELECT CupoMaximo FROM CursoHabilitado WHERE CursoHabilitadoID = v_CursoHabilitadoID LIMIT 1);

    SET v_CantidadEstudiantesAsignados = (SELECT CantidadEstudiantesAsignados FROM CursoHabilitado WHERE CursoHabilitadoID = v_CursoHabilitadoID LIMIT 1);

    IF v_CantidadEstudiantesAsignados >= v_CupoMaximo THEN
        SET v_Error = 'El cupo máximo para este curso ya se ha alcanzado.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Asignar el curso al estudiante
    INSERT INTO AsignacionCurso (Carnet, CursoHabilitadoID)
    VALUES (p_Carnet, v_CursoHabilitadoID);

    -- Actualizar la cantidad de estudiantes asignados en CursoHabilitado
    UPDATE CursoHabilitado
    SET CantidadEstudiantesAsignados = v_CantidadEstudiantesAsignados + 1
    WHERE CursoHabilitadoID = v_CursoHabilitadoID;
END;
//

DELIMITER ;


--FUNCION 8

DELIMITER //

CREATE PROCEDURE desasignarCurso(
    IN p_CursoCodigo BIGINT,
    IN p_Ciclo VARCHAR(2),
    IN p_Seccion CHAR(1),
    IN p_Carnet BIGINT
)
BEGIN
    DECLARE v_Error VARCHAR(255);
    DECLARE v_CursoHabilitadoID BIGINT;
    DECLARE v_CantidadEstudiantesAsignados NUMERIC;

    -- Verificar si el carnet del estudiante existe
    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE Carnet = p_Carnet) THEN
        SET v_Error = 'El carnet del estudiante no existe en la base de datos';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Validar que el curso habilitado existe
    SET v_CursoHabilitadoID = (SELECT CursoHabilitadoID FROM CursoHabilitado WHERE CursoCodigo = p_CursoCodigo AND Ciclo = p_Ciclo AND Seccion = p_Seccion AND YEAR(NOW()) = YEAR(CursoHabilitado.FechaCreacion) LIMIT 1);

    IF v_CursoHabilitadoID IS NULL THEN
        SET v_Error = 'El curso habilitado especificado no existe en la base de datos para el año actual, ciclo y sección.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Verificar si el estudiante está asignado al curso
    IF NOT EXISTS (SELECT 1 FROM AsignacionCurso WHERE Carnet = p_Carnet AND CursoHabilitadoID = v_CursoHabilitadoID) THEN
        SET v_Error = 'El estudiante no está asignado al curso y sección especificados.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Desasignar el curso del estudiante
    DELETE FROM AsignacionCurso WHERE Carnet = p_Carnet AND CursoHabilitadoID = v_CursoHabilitadoID;

    -- Actualizar la cantidad de estudiantes asignados en CursoHabilitado
    SET v_CantidadEstudiantesAsignados = (SELECT CantidadEstudiantesAsignados FROM CursoHabilitado WHERE CursoHabilitadoID = v_CursoHabilitadoID LIMIT 1);

    IF v_CantidadEstudiantesAsignados > 0 THEN
        UPDATE CursoHabilitado
        SET CantidadEstudiantesAsignados = v_CantidadEstudiantesAsignados - 1
        WHERE CursoHabilitadoID = v_CursoHabilitadoID;
    END IF;
END;
//

DELIMITER ;


--FUNCION9

DELIMITER //

CREATE PROCEDURE ingresarNota(
    IN p_CursoCodigo BIGINT,
    IN p_Ciclo VARCHAR(2),
    IN p_Seccion CHAR(1),
    IN p_Carnet BIGINT,
    IN p_Nota NUMERIC
)
BEGIN
    DECLARE v_Error VARCHAR(255);
    DECLARE v_CreditosOtorga NUMERIC;
    DECLARE v_CreditosEstudiante NUMERIC;
    DECLARE v_Aprobado BOOLEAN;
    DECLARE v_CursoHabilitadoID BIGINT;

    -- Validar que el carnet del estudiante existe
    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE Carnet = p_Carnet) THEN
        SET v_Error = 'El carnet del estudiante no existe en la base de datos';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Obtener el ID del CursoHabilitado para el curso, ciclo y sección especificados
    SET v_CursoHabilitadoID = (SELECT CursoHabilitadoID FROM CursoHabilitado WHERE CursoCodigo = p_CursoCodigo AND Ciclo = p_Ciclo AND Seccion = p_Seccion AND YEAR(NOW()) = YEAR(CursoHabilitado.FechaCreacion) LIMIT 1);

    IF v_CursoHabilitadoID IS NULL THEN
        SET v_Error = 'El curso habilitado especificado no existe en la base de datos para el año actual, ciclo y sección.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Obtener la cantidad de créditos otorgados por el curso
    SET v_CreditosOtorga = (SELECT CreditosOtorga FROM Curso WHERE Codigo = p_CursoCodigo LIMIT 1);

    -- Obtener la cantidad de créditos del estudiante
    SET v_CreditosEstudiante = (SELECT Creditos FROM Estudiante WHERE Carnet = p_Carnet LIMIT 1);

    -- Calcular si el estudiante aprobó el curso y actualizar sus créditos
    IF p_Nota >= 61 THEN
        SET v_Aprobado = TRUE;
        SET v_CreditosEstudiante = v_CreditosEstudiante + v_CreditosOtorga;
    ELSE
        SET v_Aprobado = FALSE;
    END IF;

    -- Insertar la nota en la tabla Notas
    INSERT INTO Notas (CursoCodigo, Ciclo, Carnet, Nota, Anio)
    VALUES (p_CursoCodigo, p_Ciclo, p_Carnet, ROUND(p_Nota), YEAR(NOW()));

    -- Actualizar el estado de aprobación en la tabla Estudiante
    UPDATE Estudiante
    SET Creditos = v_CreditosEstudiante,
        Aprobado = v_Aprobado
    WHERE Carnet = p_Carnet;
END;
//

DELIMITER ;


--FUNCION 10
DELIMITER //

CREATE PROCEDURE generarActa(
    IN p_CursoCodigo BIGINT,
    IN p_Ciclo VARCHAR(2),
    IN p_Seccion CHAR(1)
)
BEGIN
    DECLARE v_Error VARCHAR(255);
    DECLARE v_NumEstudiantesAsignados BIGINT;
    DECLARE v_NumEstudiantesNotasIngresadas BIGINT;
    DECLARE v_ActaID BIGINT;

    -- Validar que el curso exista
    IF NOT EXISTS (SELECT 1 FROM Curso WHERE Codigo = p_CursoCodigo) THEN
        SET v_Error = 'El curso especificado no existe en la base de datos';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Obtener el ID del CursoHabilitado para el curso, ciclo y sección especificados
    SET v_ActaID = (SELECT ActasID FROM Actas WHERE CursoHabilitadoID IN (SELECT CursoHabilitadoID FROM CursoHabilitado WHERE CursoCodigo = p_CursoCodigo AND Ciclo = p_Ciclo AND Seccion = p_Seccion AND YEAR(NOW()) = YEAR(CursoHabilitado.FechaCreacion)) LIMIT 1);

    -- Verificar si se ha generado un acta para el curso, ciclo y sección especificados
    IF v_ActaID IS NOT NULL THEN
        SET v_Error = 'Ya se ha generado un acta para el curso, ciclo y sección especificados.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Contar la cantidad de estudiantes asignados al curso
    SET v_NumEstudiantesAsignados = (SELECT COUNT(*) FROM AsignacionCurso WHERE CursoHabilitadoID IN (SELECT CursoHabilitadoID FROM CursoHabilitado WHERE CursoCodigo = p_CursoCodigo AND Ciclo = p_Ciclo AND Seccion = p_Seccion AND YEAR(NOW()) = YEAR(CursoHabilitado.FechaCreacion)));

    -- Contar la cantidad de estudiantes a los que se les han ingresado notas
    SET v_NumEstudiantesNotasIngresadas = (SELECT COUNT(*) FROM Notas WHERE CursoCodigo = p_CursoCodigo AND Ciclo = p_Ciclo);

    -- Validar que se hayan ingresado notas para todos los estudiantes asignados al curso
    IF v_NumEstudiantesNotasIngresadas < v_NumEstudiantesAsignados THEN
        SET v_Error = 'No se han ingresado notas para todos los estudiantes asignados al curso.';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_Error;
    END IF;

    -- Insertar el acta en la tabla Actas
    INSERT INTO Actas (CursoHabilitadoID, FechaGeneracion)
    SELECT CursoHabilitadoID, NOW() FROM CursoHabilitado WHERE CursoCodigo = p_CursoCodigo AND Ciclo = p_Ciclo AND Seccion = p_Seccion AND YEAR(NOW()) = YEAR(CursoHabilitado.FechaCreacion);
END;
//

DELIMITER ;



--PROCEDIMIENTOS ADICIONALES


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

CREATE PROCEDURE consultarEstudiante(
  IN p_Carnet BIGINT
)
BEGIN
  DECLARE v_Carnet BIGINT;
  DECLARE v_NombreCompleto VARCHAR(255);
  DECLARE v_FechaNacimiento DATE;
  DECLARE v_Correo VARCHAR(255);
  DECLARE v_Telefono BIGINT;
  DECLARE v_Direccion VARCHAR(255);
  DECLARE v_NumeroDPI BIGINT;
  DECLARE v_Carrera VARCHAR(255);
  DECLARE v_Creditos NUMERIC;
  
  -- Verificar si el estudiante con el carnet dado existe
  SELECT Estudiante.Carnet, CONCAT(Persona.Nombres, ' ', Persona.Apellidos) AS NombreCompleto, Persona.FechaNacimiento, Persona.Correo, Persona.Telefono, Persona.Direccion, Persona.NumeroDPI, Carrera.Nombre AS Carrera, Estudiante.Creditos
  INTO v_Carnet, v_NombreCompleto, v_FechaNacimiento, v_Correo, v_Telefono, v_Direccion, v_NumeroDPI, v_Carrera, v_Creditos
  FROM Estudiante
  INNER JOIN Persona ON Estudiante.PersonaID = Persona.ID
  INNER JOIN Carrera ON Estudiante.CarreraID = Carrera.CarreraID
  WHERE Estudiante.Carnet = p_Carnet;
  
  -- Si no se encuentra ningún estudiante, mostrar un mensaje de error
  IF v_Carnet IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estudiante no encontrado';
  END IF;
  
  -- Devolver los datos del estudiante
  SELECT v_Carnet AS 'Carnet',
         v_NombreCompleto AS 'Nombre Completo',
         v_FechaNacimiento AS 'Fecha de Nacimiento',
         v_Correo AS 'Correo',
         v_Telefono AS 'Teléfono',
         v_Direccion AS 'Dirección',
         v_NumeroDPI AS 'Número de DPI',
         v_Carrera AS 'Carrera',
         v_Creditos AS 'Créditos que posee';
END //

DELIMITER ;



--PROCE3

DELIMITER //

CREATE PROCEDURE consultarDocente(
  IN p_RegistroSIIF BIGINT
)
BEGIN
  DECLARE v_RegistroSIIF BIGINT;
  DECLARE v_NombreCompleto VARCHAR(255);
  DECLARE v_FechaNacimiento DATE;
  DECLARE v_Correo VARCHAR(255);
  DECLARE v_Telefono BIGINT;
  DECLARE v_Direccion VARCHAR(255);
  DECLARE v_NumeroDPI BIGINT;

  -- Verificar si el docente con el Registro SIIF dado existe
  SELECT Docente.RegistroSIIF, CONCAT(Persona.Nombres, ' ', Persona.Apellidos) AS NombreCompleto, Persona.FechaNacimiento, Persona.Correo, Persona.Telefono, Persona.Direccion, Persona.NumeroDPI
  INTO v_RegistroSIIF, v_NombreCompleto, v_FechaNacimiento, v_Correo, v_Telefono, v_Direccion, v_NumeroDPI
  FROM Docente
  INNER JOIN Persona ON Docente.PersonaID = Persona.ID
  WHERE Docente.RegistroSIIF = p_RegistroSIIF;

  -- Si no se encuentra ningún docente, mostrar un mensaje de error
  IF v_RegistroSIIF IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Docente no encontrado';
  END IF;

  -- Devolver los datos del docente
  SELECT v_RegistroSIIF AS 'Registro SIIF',
         v_NombreCompleto AS 'Nombre Completo',
         v_FechaNacimiento AS 'Fecha de Nacimiento',
         v_Correo AS 'Correo',
         v_Telefono AS 'Teléfono',
         v_Direccion AS 'Dirección',
         v_NumeroDPI AS 'Número de DPI';
END //

DELIMITER ;



--PROCE4
DELIMITER //

CREATE PROCEDURE consultarAsignados(
  IN p_CodigoCurso BIGINT,
  IN p_Ciclo VARCHAR(2),
  IN p_Anio BIGINT,
  IN p_Seccion CHAR(1)
)
BEGIN
  -- Declarar una variable para el CursoHabilitadoID
  DECLARE v_CursoHabilitadoID BIGINT;

  -- Obtener el CursoHabilitadoID para el curso, ciclo, año y sección especificados
  SELECT CursoHabilitado.CursoHabilitadoID
  INTO v_CursoHabilitadoID
  FROM CursoHabilitado
  WHERE CursoHabilitado.CursoCodigo = p_CodigoCurso
  AND CursoHabilitado.Ciclo = p_Ciclo
  AND CursoHabilitado.Anio = p_Anio
  AND CursoHabilitado.Seccion = p_Seccion;

  -- Verificar si se encontró un CursoHabilitado
  IF v_CursoHabilitadoID IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Curso y sección no encontrados para el ciclo y año especificados';
  ELSE
    -- Seleccionar y mostrar la lista de estudiantes asignados al curso
    SELECT Estudiante.Carnet, CONCAT(Persona.Nombres, ' ', Persona.Apellidos) AS 'Nombre Completo', Estudiante.Creditos
    FROM AsignacionCurso
    INNER JOIN Estudiante ON AsignacionCurso.Carnet = Estudiante.Carnet
    INNER JOIN Persona ON Estudiante.PersonaID = Persona.ID
    WHERE AsignacionCurso.CursoHabilitadoID = v_CursoHabilitadoID;
  END IF;
END //

DELIMITER ;



--PROCE5
DELIMITER //

CREATE PROCEDURE consultarAprobacion(
  IN p_CodigoCurso BIGINT,
  IN p_Ciclo VARCHAR(2),
  IN p_Anio BIGINT,
  IN p_Seccion CHAR(1)
)
BEGIN
  -- Declarar una variable para el CursoHabilitadoID
  DECLARE v_CursoHabilitadoID BIGINT;

  -- Obtener el CursoHabilitadoID para el curso, ciclo, año y sección especificados
  SELECT CursoHabilitado.CursoHabilitadoID
  INTO v_CursoHabilitadoID
  FROM CursoHabilitado
  WHERE CursoHabilitado.CursoCodigo = p_CodigoCurso
  AND CursoHabilitado.Ciclo = p_Ciclo
  AND CursoHabilitado.Anio = p_Anio
  AND CursoHabilitado.Seccion = p_Seccion;

  -- Verificar si se encontró un CursoHabilitado
  IF v_CursoHabilitadoID IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Curso y sección no encontrados para el ciclo y año especificados';
  ELSE
    -- Seleccionar y mostrar la lista de estudiantes y si aprobaron o reprobaron el curso
    SELECT p_CodigoCurso AS 'Código de curso', AsignacionCurso.Carnet, CONCAT(Persona.Nombres, ' ', Persona.Apellidos) AS 'Nombre Completo',
      CASE
        WHEN Notas.Nota >= 61 THEN 'APROBADO'
        ELSE 'DESAPROBADO'
      END AS 'Estado'
    FROM AsignacionCurso
    INNER JOIN Estudiante ON AsignacionCurso.Carnet = Estudiante.Carnet
    INNER JOIN Persona ON Estudiante.PersonaID = Persona.ID
    LEFT JOIN Notas ON AsignacionCurso.CursoHabilitadoID = v_CursoHabilitadoID AND AsignacionCurso.Carnet = Notas.Carnet;
  END IF;
END //

DELIMITER ;


--PROCE 6

DELIMITER //

CREATE PROCEDURE consultarActas(
  IN p_CodigoCurso BIGINT
)
BEGIN
  -- Verificar si el curso existe
  DECLARE cursoExiste INT;
  SELECT COUNT(*) INTO cursoExiste FROM Curso WHERE Codigo = p_CodigoCurso;

  IF cursoExiste = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Curso no encontrado';
  ELSE
    -- Seleccionar y mostrar el listado de actas del curso ordenadas por fecha y hora de generación
    SELECT 
      p_CodigoCurso AS 'Código de curso',
      a.Seccion,
      CASE
        WHEN a.Ciclo = '1S' THEN 'PRIMER SEMESTRE'
        WHEN a.Ciclo = '2S' THEN 'SEGUNDO SEMESTRE'
        WHEN a.Ciclo = 'VJ' THEN 'VACACIONES DE JUNIO'
        WHEN a.Ciclo = 'VD' THEN 'VACACIONES DE DICIEMBRE'
        ELSE 'Desconocido'
      END AS 'Ciclo',
      a.Anio AS 'Año',
      a.CantidadEstudiantesAsignados AS 'Cantidad de estudiantes que llevaron el curso',
      a.FechaGeneracion AS 'Fecha y hora de generado'
    FROM CursoHabilitado a
    WHERE a.CursoCodigo = p_CodigoCurso
    ORDER BY a.FechaGeneracion;
  END IF;
END //

DELIMITER ;

--PROCE7

DELIMITER //

CREATE PROCEDURE consultarDesasignacion(
  IN p_CodigoCurso BIGINT,
  IN p_Ciclo VARCHAR(2),
  IN p_Anio BIGINT,
  IN p_Seccion CHAR(1)
)
BEGIN
  -- Declarar variables para almacenar la cantidad de estudiantes que llevaron el curso y la cantidad de estudiantes que se desasignaron
  DECLARE estudiantesLlevaronCurso INT;
  DECLARE estudiantesDesasignados INT;
  DECLARE porcentajeDesasignacion DECIMAL(5, 2);  -- Definir la variable de porcentaje de desasignación
  
  -- Inicializar la variable de porcentaje de desasignación
  SET porcentajeDesasignacion = 0.0;
  
  -- Calcular la cantidad de estudiantes que llevaron el curso
  SELECT COUNT(*) INTO estudiantesLlevaronCurso
  FROM AsignacionCurso ac
  JOIN CursoHabilitado ch ON ac.CursoHabilitadoID = ch.CursoHabilitadoID
  WHERE ch.CursoCodigo = p_CodigoCurso AND ch.Ciclo = p_Ciclo AND ch.Anio = p_Anio AND ch.Seccion = p_Seccion;
  
  -- Calcular la cantidad de estudiantes que se desasignaron
  SELECT COUNT(*) INTO estudiantesDesasignados
  FROM CursoHabilitado ch
  LEFT JOIN AsignacionCurso ac ON ch.CursoHabilitadoID = ac.CursoHabilitadoID
  WHERE ch.CursoCodigo = p_CodigoCurso AND ch.Ciclo = p_Ciclo AND ch.Anio = p_Anio AND ch.Seccion = p_Seccion
  AND ac.Carnet IS NULL;
  
  -- Calcular el porcentaje de desasignación
  IF estudiantesLlevaronCurso > 0 THEN
    SET porcentajeDesasignacion = (estudiantesDesasignados / estudiantesLlevaronCurso) * 100;
  END IF;
  
  -- Seleccionar y mostrar los resultados
  SELECT
    p_CodigoCurso AS 'Código de curso',
    p_Seccion AS 'Sección',
    CASE
      WHEN p_Ciclo = '1S' THEN 'PRIMER SEMESTRE'
      WHEN p_Ciclo = '2S' THEN 'SEGUNDO SEMESTRE'
      WHEN p_Ciclo = 'VJ' THEN 'VACACIONES DE JUNIO'
      WHEN p_Ciclo = 'VD' THEN 'VACACIONES DE DICIEMBRE'
      ELSE 'Desconocido'
    END AS 'Ciclo',
    p_Anio AS 'Año',
    estudiantesLlevaronCurso AS 'Cantidad de estudiantes que llevaron el curso',
    estudiantesDesasignados AS 'Cantidad de estudiantes que se desasignaron',
    porcentajeDesasignacion AS 'Porcentaje de desasignación';
END //

DELIMITER ;





