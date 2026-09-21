package Conexion;

# ---------------------------------------------------------------------------
# Conexion.pm
# Conexion
# Proyecto: Base de datos no relacional - Zoologico (CouchDB + Perl)
#
# CouchDB no tiene un driver nativo como MySQL: se maneja 100% por su
# API REST sobre HTTP con JSON. Por eso "conectar" en realidad significa
# armar un cliente HTTP con la URL base y las credenciales correctas.
#
# Modulos usados (todos del core de Perl, no requieren cpan install):
#   HTTP::Tiny    -> cliente HTTP
#   JSON::PP      -> codificar/decodificar JSON
#   MIME::Base64  -> autenticacion basica (usuario:contrasenia)
# ---------------------------------------------------------------------------

use strict;
use warnings;
use utf8;

use HTTP::Tiny;
use JSON::PP;
use MIME::Base64 qw(encode_base64);
use Exporter 'import';

our @EXPORT_OK = qw(conectar);

# ---------------------------------------------------------------------------
# EDITAR ACA: datos de conexion segun lo configurado en Fauxton.
# En un proyecto real esto podria ir en variables de entorno, pero para
# la tarea alcanza con dejarlo declarado y que cada uno lo ajuste a su
# instalacion local.
# ---------------------------------------------------------------------------
our %CONFIG = (
    host     => 'localhost',
    port     => 5984,
    usuario  => 'admin',
    password => 'admin1234',
    base     => 'zoologico',
);

# ---------------------------------------------------------------------------
# conectar(%overrides)
#
# Arma y devuelve el objeto de conexion. Se le pueden pasar valores para
# sobreescribir la configuracion por defecto, por ejemplo:
#
#   my $conexion = conectar();                       # usa %CONFIG
#   my $conexion = conectar(base => 'zoologico_test'); # otra base
#
# El objeto devuelto es lo que los demas reciben como primer
# parametro en sus funciones: crear_documento($conexion, ...), etc.
# ---------------------------------------------------------------------------
sub conectar {
    my (%overrides) = @_;

    my %datos = (%CONFIG, %overrides);

    my $self = {
        host     => $datos{host},
        port     => $datos{port},
        usuario  => $datos{usuario},
        password => $datos{password},
        base     => $datos{base},
        base_url => "http://$datos{host}:$datos{port}",
    };

    $self->{http} = HTTP::Tiny->new(
        agent      => 'Zoologico-Perl-CouchDB/1.0 ',
        timeout    => 10,
        keep_alive => 1,
    );

    $self->{json} = JSON::PP->new->utf8->canonical->allow_nonref;

    return bless $self, 'Conexion';
}

# ---------------------------------------------------------------------------
# peticion($conexion, $metodo, $ruta, $cuerpo)
#
# Metodo central de bajo nivel: hace la peticion HTTP a CouchDB con las
# credenciales de la conexion y devuelve la respuesta ya decodificada.
# Los demas llaman a esto desde adentro de sus propias funciones
# en vez de repetir HTTP::Tiny + JSON::PP + autenticacion cada uno.
#
#   $conexion->peticion('GET', '/zoologico/animal:001');
#   $conexion->peticion('PUT', '/zoologico/animal:001', \%documento);
#
# $ruta siempre debe empezar con '/'. Si no incluye el nombre de la base,
# usar $conexion->{base} para armarla, por ejemplo:
#   $conexion->peticion('GET', '/' . $conexion->{base} . '/_all_docs');
#
# Devuelve un hashref:
#   { ok => 1|0, status => 200, data => {...}, error => '...' }
# ---------------------------------------------------------------------------
sub peticion {
    my ($self, $metodo, $ruta, $cuerpo) = @_;

    my $url = $self->{base_url} . $ruta;

    my $token = encode_base64("$self->{usuario}:$self->{password}", '');

    my %opciones = (
        headers => {
            'Authorization' => "Basic $token",
            'Accept'        => 'application/json',
            'Content-Type'  => 'application/json',
        },
    );

    if (defined $cuerpo) {
        $opciones{content} = ref $cuerpo ? $self->{json}->encode($cuerpo) : $cuerpo;
    }

    my $res = $self->{http}->request($metodo, $url, \%opciones);

    my $data;
    if (defined $res->{content} && length $res->{content}) {
        eval { $data = $self->{json}->decode($res->{content}); 1 };
    }

    my $resultado = {
        ok     => ($res->{success} ? 1 : 0),
        status => $res->{status},
        data   => $data,
    };

    unless ($resultado->{ok}) {
        if ($res->{status} == 599) {
            $resultado->{error} = "No se pudo conectar con $self->{base_url} (revisar que CouchDB este corriendo)";
        }
        elsif (ref $data eq 'HASH' && $data->{error}) {
            $resultado->{error} = "$data->{error}: " . ($data->{reason} // '');
        }
        else {
            $resultado->{error} = "$res->{status} $res->{reason}";
        }
    }

    return $resultado;
}

# ---------------------------------------------------------------------------
# url_base($conexion)  -> URL de la base de datos configurada, ej:
#   http://localhost:5984/zoologico
# Util para que las otras personas armen sus rutas sin repetir el nombre
# de la base a mano en cada funcion.
# ---------------------------------------------------------------------------
sub url_base {
    my ($self) = @_;
    return $self->{base_url} . '/' . $self->{base};
}

1;

__END__

=head1 NAME

Conexion - Modulo de conexion a CouchDB para el proyecto del zoologico

=head1 SINOPSIS

    use lib '.';
    use Conexion qw(conectar);

    my $conexion = conectar();

    # Ejemplo de lo que haria la Persona 3 con esto:
    my $res = $conexion->peticion('GET', '/');
    if ($res->{ok}) {
        print "CouchDB version $res->{data}{version}\n";
    } else {
        print "Error: $res->{error}\n";
    }

=head1 DESCRIPCION

Queda lista la conexion
(host, puerto, usuario, contrasenia, base de datos) para que el resto
del equipo la use sin preocuparse por los detalles de HTTP ni JSON.

=head1 ACUERDO DE EQUIPO

Todas las funciones de CRUD reciben el objeto de conexion como primer
parametro:

    crear_documento($conexion, %datos);
    leer_documento($conexion, $id);
    listar_documentos($conexion);
    actualizar_documento($conexion, $id, %cambios);
    eliminar_documento($conexion, $id, $rev);

=cut