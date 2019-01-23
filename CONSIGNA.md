# Consigna

## Algo de contexto

Las aplicaciones web se dividen usualmente en frontend y backend, que se
corresponden a los componentes ejecutados en el cliente y en el servidor. El
backend, ejecutado en el servidor, implementa los diferentes procesos de
negocios, que usualmente involucran interactuar con alguna base de datos.
Recibe requests de múltiples clientes al mismo tiempo, las encola y
eventualmente envía las respuestas correspondientes. El frontend, por otra
parte, es el encargado de la visualización de los componentes gráficos en el
browser, de enviar los pedidos (HTTP Requests) al servidor y de la conexión
entre los distintos servicios provistos por el backend.

Un patrón comúnmente utilizado para implementar aplicaciones web (y en general
para aplicaciones que tenga una interfaz de usuario) es el de
Model-View-Controller. En este patrón, los modelos (Models) son los componentes
principales del patrón y expresan los comportamientos de la aplicación, es
decir implementan las reglas de negocios y administran los datos de la misma.
En aplicaciones simples, suele existir un mapeo uno a uno entre de las tablas
en la base de datos y modelos. Las vistas (Views) manejan la interacción con el
usuario y determinan cómo se renderiza la información. Luego de una acción, las
vistas envían requests a los controladores. Los controladores (Controllers) son
las funciones que abstraen la lógica de la aplicación y la interacción entre
los objetos.

En la práctica, las tareas correspondientes frontend y al backend no están
claramente definidas y varían de aplicación en aplicación. En los últimos años,
el aumento en las capacidades de procesamiento del lado del cliente provocó que
más funcionalidades fueran ejecutadas en el navegador a través de Javascript.
Como consecuencia, se desarrollaron numerosos frameworks que permiten
implementar mucho de la lógica de la aplicación, como AngularJS, React o Vue.

Para este laboratorio, el frontend está desarrollado en React e implementa las
vistas: toda la lógica de visualizaciones, redirecciones entre pantallas, etc.
El frontend se comunica con el backend a través de una API RESTful previamente
definida. El backend actúa, a todos los fines prácticos, como una abstracción
de la base de datos que provee las funcionalidades relacionadas al manejo de
modelos. Se compone de los controladores y de los modelos.

## El proyecto

En este laboratorio vamos a implementar una API RESTful para un servicio de
delivery, al estilo pedidosya, ifood o deliveroo. La cátedra les proveerá de un
esqueleto inicial, la especificación de la API y el frontend compilado.

El backend estará implementado en Sinatra, un framework web para Ruby. Tendrán
que completar el esqueleto implementando las funciones que procesan las
peticiones HTTP (POST y GET) que vienen del frontend, y definiendo los modelos.
Tengan en cuenta también que están diseñando un prototipo, por lo cual el
diseño de la aplicación debe ser lo suficientemente flexible para poder
adaptarse a cambios futuros e incorporar nuevas funcionalidades a medida que
los requerimientos de los usuarios evolucionen.

### Algunas simplificaciones

Para mantener simple nuestro prototipo, tomaremos algunas decisiones de diseño
que no son óptimas si estuviéramos implementando un producto real.

-   Nuestra base de datos será implementada mediante archivos JSON. Esto es,
    guardaremos los objetos (usuarios registrados, ubicaciones, pedidos y
    productos) en formato JSON. De esta forma, no hay que preocuparse por
    configurar una base de datos.

-   En lugar de usar alguna interfaz a google maps, las ubicaciones serán
    simples strings predefinidos con nombres como “Parque Sarmiento” o “Alta
    Córdoba”. No se podrán cambiar desde la app.

-   No es necesario manejar los casos de uso con errores "elegantemente". Por
    ejemplo, si los mails ingresados no son válidos o los números de teléfono
    tienen letras. Tampoco estamos validando contraseñas ni comprobando
    exhaustivamente la seguridad de la aplicación.

-   A la hora de listar los proveedores para un comensal en particular,
    listaremos solamente aquellos que tengan la misma ubicación. El campo
    max\_delivery\_rate se utilizará sólo para los puntos estrellas.


## Requerimientos Funcionales

1.  Registro y Login de usuarios. Los usuarios pueden ser comensales
    (consumers) o proveedores (providers), no ambos al mismo tiempo. El
    registro de usuarios es diferenciado, pero el login no, es una única
    pantalla para comensales y proveedores. Los comensales tienen un nombre de
    usuario, una dirección y una contraseña. Los proveedores tienen, además de
    lo anterior, un nombre del negocio y una distancia máxima de delivery.
    Todos están unívocamente determinados por su nombre de usuario.

2.  Comensales (consumer):
  1.  Ingresar una dirección (la suya propia está precargada) y obtener un
      listado de proveedores que realicen deliveries a esa ubicación
      particular. Para ello, deberán tener en cuenta que los proveedores tienen
      un radio máximo de distancia para las entregas.
  2.  Crear un pedido (order) a un único proveedor través de la selección de
      múltiples ítems.  Una vez que todos los ítems del pedido han sido
      elegidos, el comensal puede pagar el pedido realizado. \[Esta acción
      afecta el saldo del proveedor y guarda el pedido con estado ‘payed’\]
  3.  Consultar el listado de pedidos realizados con sus respectivos estados, y
      consultar su saldo total.

3.  Proveedores (providers):
  1.  Crear un menú compuesto de ítems. Cada ítem debe tener una descripción y
      un precio. Un proveedor sólo puede modificar los items creados por el
      mismo.
    2.  Consultar su perfil donde se listan los pedidos realizados con sus
        respectivos estados  y el saldo (balance).
    3.  Ver los pedidos pendientes y marcalos como finalizados. \[Esta acción
        cambia el estado del pedido a ‘delivered’\]


## Implementación

Por sobre todo, tengan en cuenta que se evaluará el diseño de los objetos y la
utilización de conceptos como herencia, encapsulamiento, uso adecuado de
métodos, atributos de clase y atributos de instancias.

Alguno de las clases que creen deberán tener persistencia en la base de datos
(archivos json). Esto involucra no solo leer y escribir los objetos en el
disco, sino también por buscarlos de forma eficiente. Por ello, les proveemos
una clase base Model con algunas funciones auxiliares ya implementadas. Tiene
la opción de heredar de esta clase para crear nuevos modelos.

### Definición de la API


| Method | URL                             | Params                                                                                                | Code - Response                                                                                                                                                                                                                          |
|--------|---------------------------------|-------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| POST   | /api/login                      | {email: string,   password: string}                                                                   | 200 - {id: int, isProvider: bool};   401 non existing user;   403 incorrect password                                                                                                                                                     |
| POST   | /api/logout                     | {}                                                                                                    | 200                                                                                                                                                                                                                                      |
| POST   | /api/consumers                  | {email: string,  location: int,  password: string}                                                    | 200 id as string;  400 no email/location;   409 existing user                                                                                                                                                                            |
| POST   | /api/providers                  | {email: string,  store_name: string,  location: int,  password: string, max_delivery_distance: float} | 200 id as string;   400 no email/location/store_name;   409 existing provider                                                                                                                                                            |
| POST   | /api/items                      | {name: string,  price: float,  provider: int}                                                         | 200 id as string;  409 duplicate item for provider;  404 non existing provider;  400 no name/price/provider                                                                                                                              |
| POST   | /api/items/delete/{id:int}      |                                                                                                       | 200;  404 non existing item;  403 item not belonging to logged in provider                                                                                                                                                               |
| GET    | /api/providers                  | {location: int or nil}                                                                                       | 200 - [{id: int, email: string, location: int, store_name: string}];  404 non existing location. If location is nil, returns all the list of providers                                                                                                                   |
| GET    | /api/consumers\*\*              |                                                                                                       | 200 [{id: int, email: string, location: int}]                                                                                                                                                                                            |
| POST   | /api/users/delete/{id:int}\*\*  |                                                                                                       | 200;   404 non existing user                                                                                                                                                                                                             |
| GET    | /api/items                      | {provider: int or null}                                                                               | 200 - [{id: int,  name: string,  price: float,  provider: int}];  404 non existing provider                                                                                                                                              |
| POST   | /api/orders                     | {provider: int, items: [{id: int,amount: int}], consumer: int}                                        | 200 id as string;   404 non existing provider/item/consumer;  400 no consumer/item/provider                                                                                                                                                           |
| GET    | /api/orders/detail/:id          |                                                                                                       | 200 [{id: int,  name: string, price: float, amount: int}];  404 non existing id   400 no id                                                                                                                                              |
| GET    | /api/orders                     | {user_id: int}                                                                                        | 200 [{id: int,  provider: int, provider_name: string, consumer: int, consumer_email: string, consumer_location: int, order_amount: float, status: option(‘payed’, ‘delivered’, ‘finished’)}]; 404 non existing consumer;  400 no user_id |
| POST   | /api/deliver/{id:int}           |                                                                                                       | 200;  404 non existing order                                                                                                                                                                                                             |
| POST   | /api/orders/delete/{id:int}\*\* |                                                                                                       | 200                                                                                                                                                                                                                                      |
| GET    | /api/users/{id:int}             |                                                                                                       | 200 {email:string, balance: float, ??};  404 non existing user;   400 no user_id                                                                                                                                                         |
| GET    | /api/locations                  |                                                                                                       | 200 [{name: string, id:int}]                                                                                                                                                                                                                 |

\*\* URLs útiles para testing, no tienen contrapartida en la aplicación ReactJS


## Requerimientos No funcionales

Además de los requerimientos funcionales, el laboratorio deberá cumplir los
siguientes requerimientos no funcionales:

### Implementación:

-   No tiene que fallar con un error 500. Los 300/400 son aceptables, mientras
    que sean intencionales.

-   Deben respetar el encapsulamiento de *TODOS* los atributos. Si dan permisos
    de escritura/lectura o hacen público un método, deben poder justificar por
    qué eso era necesario.


### Estilo:

-   Estilo de código de acuerdo a [las convenciones de
    Ruby](https://github.com/bbatsov/ruby-style-guide). Les controlaremos
    principalmente indentación, estructuras básicas como if, each y unless,
    nombres de variables/funciones y largo de líneas. El código provisto está
    controlado con [Rubocop](https://github.com/bbatsov/rubocop). Si quieren
    utilizar este gem, junto con el esqueleto encontrarán un archivo
    .rubocop.yaml que especifica la configuración a utilizar.


-   El objetivo de clases, atributos y el output de métodos deben estar
    documentados en inglés. No exageren tampoco, good code is the best
    documentation.


-   Deben respetar la estructura original del proyecto, agregando nuevos
    archivos en los directorios correspondientes.
