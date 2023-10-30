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

-- Crear la función almacenada para crear una carrera
DELIMITER //
CREATE FUNCTION crearCarrera(Nombre VARCHAR(255))
RETURNS BIGINT
BEGIN
    DECLARE nuevaCarreraID BIGINT;

    -- Validar que el Nombre solo contenga letras
    IF Nombre REGEXP '^[a-zA-Z]+$' THEN
        -- Insertar la nueva carrera en la tabla Carrera
        INSERT INTO Carrera (Nombre) VALUES (Nombre);

        -- Obtener el ID de la carrera recién creada
        SET nuevaCarreraID = LAST_INSERT_ID();
    ELSE
        SET nuevaCarreraID = -1; -- Marcar un valor especial para indicar un error de validación
    END IF;

    RETURN nuevaCarreraID;
END;
//
DELIMITER ;

-- Crear el procedimiento almacenado para registrar un estudiante
DELIMITER //
CREATE PROCEDURE registrarEstudiante(
    IN Carnet BIGINT,
    IN Nombres VARCHAR(255),
    IN Apellidos VARCHAR(255),
    IN FechaNacimiento DATE,
    IN Correo VARCHAR(255),
    IN Telefono BIGINT,
    IN Direccion VARCHAR(255),
    IN NumeroDPI BIGINT,
    IN CarreraID BIGINT
)
BEGIN
    -- Validar que el Carnet no exista previamente en la tabla Estudiante
    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE Carnet = Carnet) THEN
        -- Insertar el estudiante en la tabla Estudiante
        INSERT INTO Estudiante (Carnet, Nombres, Apellidos, FechaNacimiento, Correo, Telefono, Direccion, NumeroDPI, CarreraID)
        VALUES (Carnet, Nombres, Apellidos, FechaNacimiento, Correo, Telefono, Direccion, NumeroDPI, CarreraID);
        
        -- Registrar la fecha de creación
        UPDATE Estudiante
        SET FechaCreacion = NOW()
        WHERE Carnet = Carnet;
    END IF;
END;
//
DELIMITER ;

-- Crear el procedimiento almacenado para registrar un docente
DELIMITER //
CREATE PROCEDURE registrarDocente(
    IN Nombres VARCHAR(255),
    IN Apellidos VARCHAR(255),
    IN FechaNacimiento DATE,
    IN Correo VARCHAR(255),
    IN Telefono BIGINT,
    IN Direccion VARCHAR(255),
    IN NumeroDPI BIGINT,
    IN RegistroSIIF BIGINT
)
BEGIN
    -- Validar que el docente no exista previamente en la tabla Docente
    IF NOT EXISTS (SELECT 1 FROM Docente WHERE RegistroSIIF = RegistroSIIF) THEN
        -- Insertar el docente en la tabla Docente
        INSERT INTO Docente (Nombres, Apellidos, FechaNacimiento, Correo, Telefono, Direccion, NumeroDPI, RegistroSIIF)
        VALUES (Nombres, Apellidos, FechaNacimiento, Correo, Telefono, Direccion, NumeroDPI, RegistroSIIF);
        
        -- Registrar la fecha de creación
        UPDATE Docente
        SET FechaCreacion = NOW()
        WHERE RegistroSIIF = RegistroSIIF;
    END IF;
END;
//
DELIMITER ;

-- Crear el procedimiento almacenado para crear un curso con validaciones
DELIMITER //
CREATE PROCEDURE crearCurso(
    IN Codigo BIGINT,
    IN Nombre VARCHAR(255),
    IN CreditosNecesarios NUMERIC,
    IN CreditosOtorga NUMERIC,
    IN CarreraID BIGINT,
    IN EsObligatorio BOOLEAN
)
BEGIN
    -- Validar que el curso no exista previamente en la tabla Curso
    IF NOT EXISTS (SELECT 1 FROM Curso WHERE Codigo = Codigo) THEN
        -- Validar que los créditos necesarios sean 0 o un entero positivo
        IF CreditosNecesarios >= 0 THEN
            -- Validar que los créditos que otorga sean un entero positivo
            IF CreditosOtorga >= 0 THEN
                -- Validar que la carrera a la que pertenece sea un entero positivo o 0 (área común)
                IF CarreraID >= 0 OR CarreraID = 0 THEN
                    -- Validar que EsObligatorio sea 0 o 1
                    IF EsObligatorio IN (0, 1) THEN
                        -- Insertar el curso en la tabla Curso
                        INSERT INTO Curso (Codigo, Nombre, CreditosNecesarios, CreditosOtorga, CarreraID, EsObligatorio)
                        VALUES (Codigo, Nombre, CreditosNecesarios, CreditosOtorga, CarreraID, EsObligatorio);
                    ELSE
                        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El valor de EsObligatorio debe ser 0 o 1.';
                    END IF;
                ELSE
                    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El valor de CarreraID debe ser un entero positivo o 0 (área común).';
                END IF;
            ELSE
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los créditos que otorga deben ser un entero positivo.';
            END IF;
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Los créditos necesarios deben ser 0 o un entero positivo.';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El curso con Código ' + Codigo + ' ya existe en la base de datos.';
    END IF;
END;
//
DELIMITER ;

-- Crear el procedimiento almacenado para habilitar un curso para asignación con validaciones
DELIMITER //
CREATE PROCEDURE habilitarCurso(
    IN CursoCodigo BIGINT,
    IN Ciclo VARCHAR(2),
    IN DocenteRegistroSIIF BIGINT,
    IN CupoMaximo BIGINT,
    IN Seccion CHAR(1)
)
BEGIN
    DECLARE CursoHabilitadoID BIGINT;

    -- Validar que el curso exista en la tabla Curso
    IF EXISTS (SELECT 1 FROM Curso WHERE Codigo = CursoCodigo) THEN
        -- Validar que el Ciclo sea uno de los valores permitidos
        IF Ciclo IN ('1S', '2S', 'VJ', 'VD') THEN
            -- Validar que el Docente exista en la tabla Docente
            IF EXISTS (SELECT 1 FROM Docente WHERE RegistroSIIF = DocenteRegistroSIIF) THEN
                -- Validar que el CupoMaximo sea un número entero positivo
                IF CupoMaximo > 0 THEN
                    -- Validar que la Sección sea una sola letra en mayúscula
                    IF LENGTH(Seccion) = 1 AND Seccion REGEXP '^[A-Z]$' THEN
                        -- Insertar la disponibilidad del curso en la tabla CursoHabilitado
                        INSERT INTO CursoHabilitado (CursoCodigo, Ciclo, DocenteRegistroSIIF, CupoMaximo, Seccion, Anio, CantidadEstudiantesAsignados)
                        VALUES (CursoCodigo, Ciclo, DocenteRegistroSIIF, CupoMaximo, UPPER(Seccion), YEAR(NOW()), 0);

                        -- Obtener el ID del curso habilitado recién creado
                        SET CursoHabilitadoID = LAST_INSERT_ID();
                        
                        -- Devolver el ID del curso habilitado
                        SELECT CursoHabilitadoID AS 'ID del Curso Habilitado';
                    ELSE
                        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La sección debe ser una sola letra en mayúscula.';
                    END IF;
                ELSE
                    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El CupoMaximo debe ser un número entero positivo.';
                END IF;
            ELSE
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El Docente con RegistroSIIF ' + DocenteRegistroSIIF + ' no existe en la base de datos.';
            END IF;
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El Ciclo debe ser uno de los siguientes valores: ''1S'', ''2S'', ''VJ'', ''VD''.';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El curso con Código ' + CursoCodigo + ' no existe en la base de datos.';
    END IF;
END;
//
DELIMITER ;


-- Crear el procedimiento almacenado para agregar un horario a un curso habilitado
DELIMITER //
CREATE PROCEDURE agregarHorarioCurso(
    IN CursoHabilitadoID BIGINT,
    IN DiaSemana NUMERIC,
    IN HoraInicio TIME,
    IN HoraFin TIME
)
BEGIN
    -- Validar que el CursoHabilitadoID exista en la tabla CursoHabilitado
    IF EXISTS (SELECT 1 FROM CursoHabilitado WHERE CursoHabilitadoID = CursoHabilitadoID) THEN
        -- Validar que el DiaSemana esté dentro del dominio [1, 7]
        IF DiaSemana BETWEEN 1 AND 7 THEN
            -- Validar que la HoraInicio sea menor que la HoraFin
            IF HoraInicio < HoraFin THEN
                -- Insertar el horario del curso habilitado en la tabla HorarioCurso
                INSERT INTO HorarioCurso (CursoHabilitadoID, DiaSemana, HoraInicio, HoraFin)
                VALUES (CursoHabilitadoID, DiaSemana, HoraInicio, HoraFin);
                
                -- Devolver un mensaje de éxito
                SELECT 'Horario agregado con éxito.' AS 'Mensaje';
            ELSE
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La HoraInicio debe ser menor que la HoraFin.';
            END IF;
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El Día de la semana debe estar dentro del dominio [1, 7].';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El CursoHabilitado con ID ' + CursoHabilitadoID + ' no existe en la base de datos.';
    END IF;
END;
//
DELIMITER ;


-- Crear el procedimiento almacenado para asignar un estudiante a un curso
DELIMITER //
CREATE PROCEDURE asignarCurso(
    IN CursoCodigo BIGINT,
    IN Ciclo VARCHAR(2),
    IN Seccion CHAR(1),
    IN Carnet BIGINT
)
BEGIN
    DECLARE CursoHabilitadoID BIGINT;
    DECLARE CreditosNecesariosCurso NUMERIC;
    DECLARE CreditosEstudiante NUMERIC;
    DECLARE CupoActual BIGINT;

    -- Validar que el carnet del estudiante exista
    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE Carnet = Carnet) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El carnet del estudiante no existe en la base de datos.';
    ELSE
        -- Obtener el ID del curso habilitado correspondiente al año actual, ciclo y sección
        SET CursoHabilitadoID = (SELECT CursoHabilitadoID FROM CursoHabilitado 
                                 WHERE CursoCodigo = CursoCodigo AND Ciclo = Ciclo AND Seccion = Seccion AND Anio = YEAR(NOW()));

        -- Validar que el CursoHabilitadoID exista
        IF CursoHabilitadoID IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se encontró un curso habilitado con los parámetros especificados.';
        ELSE
            -- Obtener los créditos necesarios para el curso
            SET CreditosNecesariosCurso = (SELECT CreditosNecesarios FROM Curso WHERE Codigo = CursoCodigo);

            -- Obtener los créditos totales del estudiante
            SET CreditosEstudiante = (SELECT Creditos FROM Estudiante WHERE Carnet = Carnet);

            -- Validar que el estudiante tenga los créditos necesarios para el curso
            IF CreditosEstudiante >= CreditosNecesariosCurso THEN
                -- Obtener el cupo actual del curso habilitado
                SET CupoActual = (SELECT CantidadEstudiantesAsignados FROM CursoHabilitado WHERE CursoHabilitadoID = CursoHabilitadoID);

                -- Validar que la sección del curso exista y no haya alcanzado el cupo máximo
                IF CupoActual < (SELECT CupoMaximo FROM CursoHabilitado WHERE CursoHabilitadoID = CursoHabilitadoID) THEN
                    -- Insertar la asignación del estudiante al curso
                    INSERT INTO AsignacionCurso (Carnet, CursoHabilitadoID)
                    VALUES (Carnet, CursoHabilitadoID);

                    -- Incrementar el contador de estudiantes asignados en el curso habilitado
                    UPDATE CursoHabilitado
                    SET CantidadEstudiantesAsignados = CupoActual + 1
                    WHERE CursoHabilitadoID = CursoHabilitadoID;

                    -- Actualizar los créditos del estudiante
                    UPDATE Estudiante
                    SET Creditos = CreditosEstudiante - CreditosNecesariosCurso
                    WHERE Carnet = Carnet;
                    
                    -- Devolver un mensaje de éxito
                    SELECT 'Asignación exitosa.' AS 'Mensaje';
                ELSE
                    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La sección seleccionada ha alcanzado el cupo máximo.';
                END IF;
            ELSE
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante no tiene los créditos necesarios para este curso.';
            END IF;
        END IF;
    END IF;
END;
//
DELIMITER ;


-- Crear el procedimiento almacenado para desasignar un estudiante de un curso
DELIMITER //
CREATE PROCEDURE desasignarCurso(
    IN CursoCodigo BIGINT,
    IN Ciclo VARCHAR(2),
    IN Seccion CHAR(1),
    IN Carnet BIGINT
)
BEGIN
    DECLARE CursoHabilitadoID BIGINT;

    -- Validar que el carnet del estudiante exista
    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE Carnet = Carnet) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El carnet del estudiante no existe en la base de datos.';
    ELSE
        -- Obtener el ID del curso habilitado correspondiente al año actual, ciclo y sección
        SET CursoHabilitadoID = (SELECT CursoHabilitadoID FROM CursoHabilitado 
                                 WHERE CursoCodigo = CursoCodigo AND Ciclo = Ciclo AND Seccion = Seccion AND Anio = YEAR(NOW()));

        -- Validar que el CursoHabilitadoID exista
        IF CursoHabilitadoID IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se encontró un curso habilitado con los parámetros especificados.';
        ELSE
            -- Validar que el estudiante esté asignado a este curso
            IF NOT EXISTS (SELECT 1 FROM AsignacionCurso WHERE Carnet = Carnet AND CursoHabilitadoID = CursoHabilitadoID) THEN
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante no está asignado a este curso.';
            ELSE
                -- Eliminar la asignación del estudiante al curso
                DELETE FROM AsignacionCurso
                WHERE Carnet = Carnet AND CursoHabilitadoID = CursoHabilitadoID;

                -- Decrementar el contador de estudiantes asignados en el curso habilitado
                UPDATE CursoHabilitado
                SET CantidadEstudiantesAsignados = CantidadEstudiantesAsignados - 1
                WHERE CursoHabilitadoID = CursoHabilitadoID;

                -- Devolver un mensaje de éxito
                SELECT 'Desasignación exitosa.' AS 'Mensaje';
            END IF;
        END IF;
    END IF;
END;
//
DELIMITER ;


-- Crear el procedimiento almacenado para ingresar notas
DELIMITER //
CREATE PROCEDURE ingresarNota(
    IN CursoCodigo BIGINT,
    IN Ciclo VARCHAR(2),
    IN Seccion CHAR(1),
    IN Carnet BIGINT,
    IN Nota NUMERIC
)
BEGIN
    DECLARE CursoHabilitadoID BIGINT;
    DECLARE CreditosEstudiante NUMERIC;

    -- Validar que el carnet del estudiante exista
    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE Carnet = Carnet) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El carnet del estudiante no existe en la base de datos.';
    ELSE
        -- Obtener el ID del curso habilitado correspondiente al año actual, ciclo y sección
        SET CursoHabilitadoID = (SELECT CursoHabilitadoID FROM CursoHabilitado 
                                 WHERE CursoCodigo = CursoCodigo AND Ciclo = Ciclo AND Seccion = Seccion AND Anio = YEAR(NOW()));

        -- Validar que el CursoHabilitadoID exista
        IF CursoHabilitadoID IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se encontró un curso habilitado con los parámetros especificados.';
        ELSE
            -- Validar que la nota sea positiva
            IF Nota >= 0 THEN
                -- Actualizar la nota del estudiante en la tabla Notas
                UPDATE Notas
                SET Nota = ROUND(Nota)  -- Redondear la nota al entero más próximo
                WHERE CursoCodigo = CursoCodigo AND Ciclo = Ciclo AND Carnet = Carnet;

                -- Obtener los créditos totales del estudiante
                SET CreditosEstudiante = (SELECT Creditos FROM Estudiante WHERE Carnet = Carnet);

                -- Obtener los créditos que otorga el curso
                DECLARE CreditosCurso NUMERIC;
                SET CreditosCurso = (SELECT CreditosOtorga FROM Curso WHERE Codigo = CursoCodigo);

                -- Validar si el estudiante aprobó el curso

-- Crear el procedimiento almacenado para generar un acta
DELIMITER //
CREATE PROCEDURE generarActa(
    IN CursoCodigo BIGINT,
    IN Ciclo VARCHAR(2),
    IN Seccion CHAR(1)
)
BEGIN
    DECLARE TotalEstudiantes BIGINT;
    DECLARE EstudiantesConNotas BIGINT;

    -- Obtener el número total de estudiantes asignados al curso habilitado
    SET TotalEstudiantes = (SELECT COUNT(*) FROM AsignacionCurso AC
                            JOIN CursoHabilitado CH ON AC.CursoHabilitadoID = CH.CursoHabilitadoID
                            WHERE CH.CursoCodigo = CursoCodigo AND CH.Ciclo = Ciclo AND CH.Seccion = Seccion);

    -- Obtener el número de estudiantes que ya tienen notas registradas
    SET EstudiantesConNotas = (SELECT COUNT(*) FROM Notas N
                               JOIN CursoHabilitado CH ON N.CursoCodigo = CH.CursoCodigo
                               WHERE CH.CursoCodigo = CursoCodigo AND CH.Ciclo = Ciclo AND CH.Seccion = Seccion);

    -- Validar que todas las notas para los estudiantes asignados estén registradas
    IF EstudiantesConNotas = TotalEstudiantes THEN
        -- Insertar el acta en la tabla Actas con la fecha y hora exacta de generación
        INSERT INTO Actas (CursoHabilitadoID, FechaGeneracion)
        SELECT CH.CursoHabilitadoID, NOW()
        FROM CursoHabilitado CH
        WHERE CH.CursoCodigo = CursoCodigo AND CH.Ciclo = Ciclo AND CH.Seccion = Seccion;
        
        -- Devolver un mensaje de éxito
        SELECT 'Generación de acta exitosa.' AS 'Mensaje';
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se pueden generar actas hasta que todas las notas estén registradas para los estudiantes asignados.';
    END IF;
END;
//
DELIMITER ;
