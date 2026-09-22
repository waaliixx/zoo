package ReadUpdate;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    leer_documento
    listar_documentos
    actualizar_documento
);

# ============================================================
# READ - Leer un documento por su _id
# ============================================================

sub leer_documento {
    my ($conexion, $id) = @_;

    my $ruta = '/' . $conexion->{base} . '/' . $id;

    return $conexion->peticion('GET', $ruta);
}

# ============================================================
# READ - Listar todos los documentos
# ============================================================

sub listar_documentos {
    my ($conexion) = @_;

    my $ruta = '/' . $conexion->{base} . '/_all_docs?include_docs=true';

    return $conexion->peticion('GET', $ruta);
}

# ============================================================
# UPDATE - Modificar un documento
# ============================================================

sub actualizar_documento {
    my ($conexion, $id) = @_;
    my $res = leer_documento($conexion, $id);

    if (!$res->{ok}) {
        return $res;
    }

    my $documento = $res->{data};
    my $rev = $documento->{_rev};

    while (1) {
        print "\n";
        print "Que desea modificar?\n";
        print "1. Nombre\n";
        print "2. Especie\n";
        print "3. Edad\n";
        print "4. Guardar cambios\n";
        print "Seleccione una opcion: ";

        chomp(my $opcion = <STDIN>);

        if ($opcion eq '1') {
            print "Nuevo nombre: ";
            chomp(my $valor = <STDIN>);

            $documento->{nombre} = $valor;
        }
        elsif ($opcion eq '2') {
            print "Nueva especie: ";
            chomp(my $valor = <STDIN>);

            $documento->{especie} = $valor;
        }
        elsif ($opcion eq '3') {
            print "Nueva edad: ";
            chomp(my $valor = <STDIN>);
            $documento->{edad} = $valor;
        }
        elsif ($opcion eq '4') {
            last;
        }
        else {
            print "Opcion no valida.\n";
        }
    }

    $documento->{_id}  = $id;
    $documento->{_rev} = $rev;

    my $ruta = '/' . $conexion->{base} . '/' . $id;
    return $conexion->peticion('PUT', $ruta, $documento);
}

1;