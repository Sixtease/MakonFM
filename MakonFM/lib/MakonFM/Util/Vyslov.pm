package MakonFM::Util::Vyslov;

use strict;
use utf8;
use Exporter qw(import);

our @EXPORT_OK = qw(vyslov);

sub vyslov {
    my $rv = '';
    for (my ($tmp) = @_) {
        if (/[^\w\s]/) {
            chomp;
            return "sp";
            next
        }
        chomp;
        init();
        prepis();
        tr/[A-Z]/[a-z]/;
        infreq();
        add_sp();
        return $_
    }
}

sub init {
    s/NISM/NYSM/g;
    s/ANTI/ANTY/g;
    s/AKTI/AKTY/g;
    s/ATIK/ATYK/g;
    s/TICK/TYCK/g;
    s/KANDI/KANDY/g;
    s/NIE/NYE/g;
    s/NII/NYY/g;
    s/ARKTI/ARKTY/g;
    s/ATRAKTI/ATRAKTY/g;
    s/AUDI/AUDY/g;
    s/AUTOMATI/AUTOMATY/g;
    s/CAUSA/KAUZA/g;
    s/CELSIA/CELZIA/g;
    s/CHIL/ČIL/g;
    s/DANIH/DANYH/g;
    s/EFEKTIV/EFEKTYV/g;
    s/FINITI/FINYTY/g;
    s/DEALER/D ii LER/g;
    s/DIAG/DYAG/g;
    s/DIET/DYET/g;
    s/DIF/DYF/g;
    s/DIG/DYG/g;
    s/DIKT/DYKT/g;
    s/DILET/DYLET/g;
    s/DIPL/DYPL/g;
    s/DIRIG/DYRYG/g;
    s/DISK/DYSK/g;
    s/DISPLAY/DYSPLEJ/g;
    s/DISP/DYSP/g;
    s/DIST/DYST/g;
    s/DIVIDE/DYVIDE/g;
    s/DUKTI/DUKTY/g;
    s/EDIC/EDYC/g;
    s/ERROR/EROR/g;
    s/^EX([AEIOUÁÉÍÓÚŮ])/EGZ$1/g;
    s/ELEKTRONI/ELEKTRONY/g;
    s/ENERGETIK/ENERGETYK/g;
    s/ETIK/ETYK/g;
    s/FEMINI/FEMINY/g;
    s/FINIŠ/FINYŠ/g;
    s/MONIE/MONYE/g;
    s/GENETI/GENETY/g;
    s/GIENI/GIENY/g;
    s/IMUNI/IMUNY/g;
    s/INDIV/INDYV/g;
    s/INICI/INYCI/g;
    s/INVESTI/INVESTY/g;
    s/KARATI/KARATY/g;
    s/KARDI/KARDY/g;
    s/KLAUS/KLAUZ/g;
    s/KOMUNI/KOMUNY/g;
    s/KONDI/KONDY/g;
    s/KREDIT/KREDYT/g;
    s/KRITI/KRITY/g;
    s/KOMODIT/KOMODYT/g;
    s/KONSOR/KONZOR/g;
    s/LEASING/L ii z ING/g;
    s/GITI/GITY/g;
    s/MEDI/MEDY/g;
    s/MOTIV/MOTYV/g;
    s/MANAG/MENEDŽ/g;
    s/NSTI/NSTY/g;
    s/TEMATI/TEMATY/g;
    s/MINI/MINY/g;
    s/MINUS/MÝNUS/g;
    s/ING/YNG/g;
    s/GATIV/GATYV/g;
    s/MATI/MATY/g;
    s/MANIP/MANYP/g;
    s/MODERNI/MODERNY/g;
    s/^NE/NE!/g;
    s/^ODD/OD!D/g;
    s/^ODT/OT!T/g;
    s/^ODI(?=[^V])/ODY/g;
    s/ORGANI/ORGANY/g;
    s/OPTIM/OPTYM/g;
    s/PANICK/PANYCK/g;
    s/PEDIATR/PEDYATR/g;
    s/PERVITI/PERVITY/g;
    s/^PODD/POD!D/g;
    s/^PODT/POT!T/g;
    s/POLITI/POLITY/g;
    s/POZIT/POZYT/g;
    s/^POULI/PO!ULI/g;
    s/PRIVATI/PRIVATY/g;
    s/PROSTITU/PROSTYTU/g;
    s/^PŘED(?=[^Ě])/PŘED!/g;
    s/RADIK/RADYK/g;
    s/^RADIO/RADYO/g;
    s/RELATIV/RELATYV/g;
    s/RESTITU/RESTYTU/g;
    s/ROCK/ROK/g;
    s/^ROZ/ROZ!/g;
    s/RUTIN/RUTYN/g;
    s/^RÁDI(.)/RÁDY$1/g;
    s/SHOP/sh O P/g;
    s/^SEBE/SEBE!/g;
    s/^SHO/SCHO/g;
    s/SOFTWAR/SOFTVER/g;
    s/SORTIM/SORTYM/g;
    s/SPEKTIV/SPEKTYV/g;
    s/SUPERLATIV/SUPERLATYV/g;
    s/NJ/Ň/g;
    s/STATISTI/STATYSTY/g;
    s/STIK/STYK/g;
    s/STIMUL/STYMUL/g;
    s/STUDI/STUDY/g;
    s/TECHNI/TECHNY/g;
    s/TELECOM/TELEKOM/g;
    s/TELEFONI/TELEFONY/g;
    s/TETIK/TETYK/g;
    s/TEXTIL/TEXTYL/g;
    s/TIBET/TYBET/g;
    s/TIBOR/TYBOR/g;
    s/TIRANY/TYRANY/g;
    s/TITUL/TYTUL/g;
    s/TRADI/TRADY/g;
    s/UNIVER/UNYVER/g;
    s/VENTI/VENTY/g;
    s/VERTIK/VERTYK/g;
}

sub prepis {
    # Hrubý fonetický přepis (skript programu sed, používán ve spojení s init.scp)
    # 11.9.1997 Autor: Nino Peterek, peterek@ufal.ms.mff.cuni.cz

    # namapování nechtěných znaků na model ticha
    s/^.*[0-9].*$/sil/g;

    # náhrada víceznakových fonémů speciálním znakem, případně rozepsání znaku na více fonémů
    s/CH/#/g;
    s/W/V/g;
    s/Q/KV/g;
    #s/DŽ/&/g;  v původním vyslov nefungovalo
    s/DZ/@/g;
    s/X/KS/g;

    # ošetření Ě 
    s/([BPFV])Ě/$1JE/g;
    s/DĚ/ĎE/g;
    s/TĚ/ŤE/g;
    s/NĚ/ŇE/g;
    s/MĚ/MŇE/g;
    s/Ě/E/g;

    # změkčující i
    s/DI/ĎI/g;
    s/TI/ŤI/g;
    s/NI/ŇI/g;
    s/DÍ/ĎÍ/g;
    s/TÍ/ŤÍ/g;
    s/NÍ/ŇÍ/g;

    # asimilace znělosti
    s/B$/P/g;
    s/B([PTŤKSŠCČ#F])/P$1/g;
    s/B([BDĎGZŽ@&H])$/P$1/g;
    s/P([BDĎGZŽ@&H])/B$1/g;
    s/D$/T/g;
    s/D([PTŤKSŠCČ#F])/T$1/g;
    s/D([BDĎGZŽ@&H])$/T$1/g;
    s/T([BDĎGZŽ@&H])/D$1/g;
    s/Ď$/Ť/g;
    s/Ď([PTŤKSŠCČ#F])/Ť$1/g;
    s/Ď([BDĎGZŽ@&H])$/Ť$1/g;
    s/Ť([BDĎGZŽ@&H])/Ď$1/g;
    s/V$/F/g;
    s/V([PTŤKSŠCČ#F])/F$1/g;
    s/V([BDĎGZŽ@&H])$/F$1/g;
    s/F([BDĎGZŽ@&H])/V$1/g;
    s/G$/K/g;
    s/G([PTŤKSŠCČ#F])/K$1/g;
    s/G([BDĎGZŽ@&H])$/K$1/g;
    s/K([BDĎGZŽ@&H])/G$1/g;
    s/Z$/S/g;
    s/Z([PTŤKSŠCČ#F])/S$1/g;
    s/Z([BDĎGZŽ@&H])$/S$1/g;
    s/S([BDĎGZŽ@&H])/Z$1/g;
    s/Ž$/Š/g;
    s/Ž([PTŤKSŠCČ#F])/Š$1/g;
    s/Ž([BDĎGZŽ@&H])$/Š$1/g;
    s/Š([BDĎGZŽ@&H])/Ž$1/g;
    s/H$/#/g;
    s/H([PTŤKSŠCČ#F])/#$1/g;
    s/H([BDĎGZŽ@&H])$/#$1/g;
    s/#([BDĎGZŽ@&H])/H$1/g;
    s/\@$/C/g;
    s/\@([PTŤKSŠCČ#F])/C$1/g;
    s/\@([BDĎGZŽ@&H])$/C$1/g;
    s/C([BDĎGZŽ@&H])/\@$1/g;
    s/&$/Č/g;
    s/&([PTŤKSŠCČ#F])/Č$1/g;
    s/&([BDĎGZŽ@&H])$/Č$1/g;
    s/Č([BDĎGZŽ@&H])/&$1/g;
    s/Ř$/>/g;
    s/Ř([PTŤKSŠCČ#F])/>$1/g;
    s/Ř([BDĎGZŽ@&H])$/>$1/g;
    s/([PTŤKSŠCČ#F])Ř/$1>/g;


    #zbytek
    s/NK/ng K/g;
    s/NG/ng G/g;
    s/MV/mg V/g;
    s/MF/mg F/g;
    s/NŤ/ŇŤ/g;
    s/NĎ/ŇĎ/g;
    s/NŇ/Ň/g;
    s/CC/C/g;
    s/DD/D/g;
    s/JJ/J/g;
    s/KK/K/g;
    s/LL/L/g;
    s/NN/N/g;
    s/MM/M/g;
    s/SS/S/g;
    s/TT/T/g;
    s/ZZ/Z/g;
    s/ČČ/Č/g;
    s/ŠŠ/Š/g;
    s/-//g;

    # závěrečný přepis na HTK abecedu
    s/>/rsh /g;
    s/EU/ew /g;
    s/AU/aw /g;
    s/OU/ow /g;
    s/Á/aa /g;
    s/Č/ch /g;
    s/Ď/dj /g;
    s/É/ee /g;
    s/Í/ii /g;
    s/Ň/nj /g;
    s/Ó/oo /g;
    s/Ř/rzh /g;
    s/Š/sh /g;
    s/Ť/tj /g;
    s/Ú/uu /g;
    s/Ů/uu /g;
    s/Ý/ii /g;
    s/Ž/zh /g;
    s/Y/i /g;
    s/&/dzh /g;
    s/\@/dz /g;
    s/#/x /g;
    s/!//g;
    s/([A-Z])/$1 /g;
#    s/$/ sp/g;
}

sub pilsen2prague {
    if (defined wantarray) {
        for (my ($tmp) = @_) {
            _pilsen2prague();
            return $tmp
        }
    }
    else { _pilsen2prague() }
}
sub _pilsen2prague {
    s/au/aw/g;
    s/cz/ch/g;
    s/ch/x/g;
    s/dzs/dzh/g;
    s/es/e s/g;
    s/eu/ew/g;
    s/ou/ow/g;
    s/rsz/rsh/g;
    s/rzs/rzh/g;
    s/sz/sh/g;
    s/ts/dz/g;
    s/zs/zh/g;
}

sub infreq {
    s/dz/c/g;
    s/dzh/ch/g;
    s/ew/e u/g;
    s/mg/m/g;
    s/oo/o/g;
}

sub add_sp {
    # skip prepositions
    return if /^(?:p (?:r(?:z (?:e t|i)| o)|o(?: t)?)|n a(?: t)?|[kosuf]|o t|d o|b e s|z a) $/;
    s/ ?$/ sp/;
}

__END__

=head1 NAME

vyslov (Czech for pronounce)

=head1 SYNOPSIS

 $ vyslov.pl [inputFile inputFile2 ...] outputFile

=head1 DESCRIPTION

converts Czech text in CAPITALS in iso-latin-2 to Czech phonetic alphabet in
iso-latin-2. All input files will be concatenated into the output file. If no
input files are specified, reads from STDIN.

If you want the script to operate in another encoding, just search for
iso-8859-2 and change it to utf8 or whatever you like. If you want to use
the Prague-style transliteration (sz instead of sh), use the pilsen2prague
function.

This is a rewrite of vyslov shell-script by Nino Peterek, which was using tools
written by Pavel Ircing. These are copy-pasted including comments into this
script.

=head1 AUTHOR

Jan Oldrich Kruza E<lt>sixtease@cpan.orgE<gt>

http://www.sixtease.net/

=head1 COPYRIGHT

Public domain
