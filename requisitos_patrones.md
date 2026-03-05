Los patrones deben de llevar una serie de reglas:
-	Se puede iniciar con un anillo mágico o con una cadena; sin embargo, el anillo mágico solo se puede utilizar al inicio del patrón.
-	 Se debe mantener consistencia entre los puntos disponibles que la vuelta anterior deja disponibles; no debe sobrar ni excederse ningún punto.
-	El tipo de punto (punto bajo, punto medio alto, punto alto, cadena, aumento, disminución, doble punto alto, triple punto alto, punto burbuja, vuelta en cadena atrás, vuelta en cadena delantera, punto recto) debe tener consistencia y lógica estructural dentro del patrón.
-	Se puede agregar un multiplicador entre bloques dentro de la vuelta o en toda la vuelta.
-	Se puede elegir entre dar una siguiente vuelta o terminar el patrón; a su vez se pueden dejar notas opcionales entre vueltas y al finalizar el patrón.
-	Cada vuelta debe indicar explícitamente los puntos resultantes totales entre paréntesis.
Reglas adicionales a considerar
-	Cada vuelta debe calcular automáticamente los puntos generados.
-	Los aumentos deben sumar correctamente puntos adicionales según su tipo.
-	Las disminuciones deben restar correctamente los puntos consumidos.
-	El multiplicador debe multiplicar correctamente los puntos contenidos en el bloque.
-	No se debe permitir un multiplicador igual o menor a uno.
-	No se deben permitir disminuciones si no hay suficientes puntos disponibles para ejecutarlas.
-	El sistema debe validar que el total calculado coincida con los puntos disponibles declarados.
-	No se debe permitir el uso de anillo mágico después de la primera vuelta.
-	No se debe permitir cerrar un patrón si existen errores matemáticos o de sintaxis.
-	El patrón debe validar su sintaxis antes de guardarse.
-	El sistema debe diferenciar entre puntos que generan puntos y puntos que solo consumen base.



Tipo de patrón
El sistema debe permitir definir el tipo de patrón:
-	Circular
-	En filas (ida y vuelta)
-	Mixto
Dependiendo del tipo:
-	En circular no se permite cadena de giro.
-	En filas se deben considerar cadenas de subida según el tipo de punto.
-	Algunas técnicas (como vuelta en cadena atrás/delantera) deben validarse según el tipo.
-	En filas debe validarse que el número de puntos al finalizar coincida con el ancho esperado.

Abreviaturas estandarizadas y puntos resultantes
El sistema debe manejar un diccionario interno de abreviaturas:
-	AM – Anillo mágico – 0 puntos resultantes (define base inicial)
-	pb – Punto bajo – 1 punto resultante
-	pma – Punto medio alto – 1 punto resultante
-	pa – Punto alto – 1 punto resultante
-	cad – Cadena – 1 punto resultante (según contexto puede no contar como punto estructural)
-	aum – Aumento – 2 puntos resultantes (consume 1 punto base)
-	aumtri – Aumento triple – 3 puntos resultantes (consume 1 punto base)
-	dis – Disminución – 1 punto resultante (consume 2 puntos base)
-	dpa – Doble punto alto – 1 punto resultante
-	tpa – Triple punto alto – 1 punto resultante
-	pbub – Punto burbuja – 1 punto resultante
Debe validar:
-	Escritura correcta.
-	Consistencia en el uso.
-	Posible estandarización por región (ES / US).
-	Que los puntos que consumen más de una base no excedan la disponibilidad.

Qué debe mostrar el patrón almacenado
Un patrón guardado debe incluir:
-	Nombre del diseño al que pertenece
-	Nombre del patrón
-	Tipo de patrón
-	Nivel de dificultad
-	Material sugerido
-	Tamaño de gancho
-	Lista completa de vueltas
-	Puntos calculados automáticamente por vuelta
-	Total, final de puntos
-	Estado del patrón (borrador / finalizado)

Validaciones del sistema
-	Validación matemática automática por vuelta.
-	Validación de coherencia entre vueltas.
-	Validación de sintaxis del patrón.
-	Detección de errores estructurales.
-	Detección de puntos no reconocidos.
-	Posibilidad de sugerencia de simplificación cuando existan bloques redundantes.
-	Mensajes de error claros indicando la vuelta y el bloque donde ocurre el problema.








Ejemplo de patrón
Nombre del diseño: Amigurumi stitch
Patrón: Cabeza Stich
R1: AM, 16pb    (16) nota: usar estambre azul
R2: 8pa, 8pb    (16)
R3: [4pma]x2, 2pa, [2aum]x3 (22)
El sistema debe:
-	Calcular automáticamente los puntos disponibles.
-	Validar que coincidan con el resultado lógico de la instrucción.
-	Detectar si existe inconsistencia matemática.
-	Impedir guardar si el total no coincide.

Requisitos UX/UI
Principios de interfaz
•	La interfaz debe ser intuitiva, clara y fácil de usar, permitiendo que usuarios con conocimientos básicos de crochet puedan crear patrones sin necesidad de escribir código o sintaxis.
•	El sistema debe priorizar la interacción visual mediante botones y selección de elementos, evitando la escritura manual del patrón.
•	Las acciones principales deben ser rápidas y accesibles, reduciendo la cantidad de pasos necesarios para crear una vuelta.
________________________________________
Creación de patrones
•	La generación del patrón debe realizarse mediante botones interactivos, donde el usuario selecciona:
o	tipo de punto
o	cantidad de puntos
o	bloques
o	multiplicadores
•	Cada acción del usuario debe agregarse visualmente a la vuelta actual, mostrando el patrón que se está construyendo en tiempo real.
Ejemplo visual generado:
R3: [4pma]x2, 2pa, [2aum]x3
•	El sistema debe mostrar automáticamente el total de puntos resultantes de la vuelta.
________________________________________
Sistema de multiplicadores
•	Al seleccionar el botón multiplicador, el sistema debe entrar en modo de agrupación de bloque.
Durante este modo:
1.	El usuario selecciona los puntos que formarán el bloque.
2.	El bloque se muestra visualmente agrupado.
3.	El usuario finaliza la agrupación.
4.	Posteriormente el sistema solicita el número de multiplicaciones.
Ejemplo de flujo:
Usuario selecciona:
4pma → agregar
terminar bloque
multiplicador → 2
Resultado:
[4pma]x2
________________________________________
Visualización del patrón
La interfaz debe mostrar:
•	La vuelta actual en edición.
•	Las vueltas anteriores.
•	Los puntos calculados automáticamente.
Ejemplo:
R1: AM, 16pb        (16)
R2: 8pa, 8pb        (16)
R3: [4pma]x2, 2pa   (10)
El total debe actualizarse en tiempo real.
________________________________________
Prevención de errores
El sistema debe prevenir errores mediante:
•	Deshabilitar acciones inválidas.
•	Mostrar advertencias visuales cuando un cálculo no coincide.
•	Indicar claramente la vuelta o bloque donde existe un error.
Ejemplos:
•	"No hay suficientes puntos disponibles para realizar una disminución."
•	"El total declarado no coincide con los puntos calculados."
________________________________________
Retroalimentación visual
La interfaz debe proporcionar feedback inmediato:
•	Resaltar bloques multiplicados.
•	Mostrar contadores de puntos.
•	Mostrar estados del patrón (válido / con errores).
•	Indicar el número de puntos disponibles para la siguiente vuelta.
________________________________________
Edición de vueltas
El usuario debe poder:
•	Editar una vuelta existente.
•	Eliminar puntos o bloques.
•	Modificar multiplicadores.
•	Recalcular automáticamente los puntos del patrón.
________________________________________
Navegación del patrón
El sistema debe permitir:
•	Agregar nuevas vueltas.
•	Eliminar vueltas.
•	Reordenar vueltas si es necesario.
•	Ver el resumen del patrón completo.
________________________________________
Estados del patrón
El patrón debe poder guardarse en diferentes estados:
•	Borrador (edición en progreso)
•	Validado (sin errores estructurales)
•	Finalizado
