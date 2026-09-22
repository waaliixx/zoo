use strict;
use warnings;

use lib '.';
use Conexion qw(conectar);

use Create qw(
    crear_documento
);

use ReadUpdate qw(
    leer_documento
    listar_documentos
    actualizar_documento
);

my $conexion = conectar();

while (1) {
    print "\n";
    print "=============================\n";
    print "         ZOOLOGICO\n";
    print "=============================\n";
    print "1. Leer documento por ID\n";
    print "2. Listar documentos\n";
    print "3. Actualizar documento\n";
    print "4. Crear documento\n";
    print "5. Salir\n";
    print "=============================\n";
    print "Seleccione una opcion: ";

    chomp(my $opcion = <STDIN>);

    if ($opcion eq '1') {

        print "Ingrese el ID: ";
        chomp(my $id = <STDIN>);

        my $res = leer_documento($conexion, $id);

        if ($res->{ok}) {

            print "\n";
            print "ID: " . ($res->{data}{_id} // '') . "\n";
            print "Rev: " . ($res->{data}{_rev} // '') . "\n";
            print "Nombre: " . ($res->{data}{nombre} // 'No disponible') . "\n";
            print "Especie: " . ($res->{data}{especie} // 'No disponible') . "\n";
            print "Edad: " . ($res->{data}{edad} // 'No disponible') . "\n";

        }
        else {
            print "Error: $res->{error}\n";
        }
    }

    elsif ($opcion eq '2') {
        my $res = listar_documentos($conexion);

        if ($res->{ok}) {
            print "\n";
            foreach my $fila (@{$res->{data}{rows}}) {
                print "ID: " . ($fila->{id} // '') . "\n";
                if ($fila->{doc}) {

                    print "Nombre: "
                        . ($fila->{doc}{nombre} // 'No disponible')
                        . "\n";

                    print "Especie: "
                        . ($fila->{doc}{especie} // 'No disponible')
                        . "\n";

                    print "Edad: "
                        . ($fila->{doc}{edad} // 'No disponible')
                        . "\n";
                }
                print "--------------------------------\n";
            }
        }
        else {

            print "Error: $res->{error}\n";
        }
    }

    elsif ($opcion eq '3') {
        print "Ingrese el ID del documento: ";
        chomp(my $id = <STDIN>);

        my $res = actualizar_documento($conexion, $id);

        if ($res->{ok}) {
            print "\n";
            print "Documento actualizado correctamente.\n";
            print "Nueva revision: "
                . ($res->{data}{rev} // '')
                . "\n";

        }
        else {
            print "\n";
            print "No se pudo actualizar el documento.\n";
            print "Error: $res->{error}\n";
        }
    }

    elsif ($opcion eq '4') {

    my $res = crear_documento($conexion);

    if ($res->{ok}) {
        print "\n";
        print "Documento creado correctamente.\n";
        print "ID generado: "
            . ($res->{data}{id} // '')
            . "\n";
        print "Revision: "
            . ($res->{data}{rev} // '')
            . "\n";
    }
    else {
        print "\n";
        print "No se pudo crear el documento.\n";
        print "Error: $res->{error}\n";
        }
    }

    elsif ($opcion eq '5') {

        print "Saliendo...\n";
        last;
    }

    else {
        print "Opcion no valida.\n";
    }
}