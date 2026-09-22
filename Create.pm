package Create;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    crear_documento
);

# ============================================================
# CREATE - Crear un nuevo documento
# ============================================================

sub crear_documento {
    my ($conexion) = @_;

    print "\n";
    print "=============================\n";
    print "      CREAR ANIMAL\n";
    print "=============================\n";

    print "Nombre: ";
    chomp(my $nombre = <STDIN>);

    print "Especie: ";
    chomp(my $especie = <STDIN>);

    print "Edad: ";
    chomp(my $edad = <STDIN>);

    # Convertir la edad a numero
    $edad = 0 + $edad;

    # Crear el documento
    my $documento = {
        nombre  => $nombre,
        especie => $especie,
        edad    => $edad,
    };

    # Ruta de la base de datos
    my $ruta = '/' . $conexion->{base};

    # POST: CouchDB genera automaticamente el _id
    return $conexion->peticion('POST', $ruta, $documento);
}

1;