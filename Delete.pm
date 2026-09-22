package Delete;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    eliminar_documento
);

# ============================================================
# DELETE - Eliminar un documento usando _id y _rev
# ============================================================

sub eliminar_documento {
    my ($conexion, $id, $rev) = @_;

    if (!defined $id || $id eq '') {
        print "Ingrese el ID del documento: ";
        chomp($id = <STDIN>);
    }

    if (!defined $rev || $rev eq '') {
        my $ruta = '/' . $conexion->{base} . '/' . $id;
        my $res = $conexion->peticion('GET', $ruta);

        if (!$res->{ok}) {
            return $res;
        }

        $rev = $res->{data}{_rev};
    }

    if (!defined $rev || $rev eq '') {
        return {
            ok     => 0,
            status => 400,
            error => 'Falta el _rev para eliminar el documento.',
        };
    }

    my $ruta = '/' . $conexion->{base} . '/' . $id . '?rev=' . $rev;
    return $conexion->peticion('DELETE', $ruta);
}

1;
