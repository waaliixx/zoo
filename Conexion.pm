package Conexion;

# ---------------------------------------------------------------------------
# Conexion.pm
# Conexion
# Proyecto: Base de datos no relacional - Zoologico (CouchDB + Perl)
#
# Modulos usados (todos del core de Perl, no se requiere instalar nada):
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

our %CONFIG = (
    host     => 'localhost',
    port     => 5984,
    usuario  => 'admin',
    password => 'admin1234',
    base     => 'zoologico',
);

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

sub url_base {
    my ($self) = @_;
    return $self->{base_url} . '/' . $self->{base};
}