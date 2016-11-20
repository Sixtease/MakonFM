package MakonFM::Util::Vyslov;

use strict;
use utf8;
use Exporter qw(import);

our @EXPORT_OK = qw(vyslov);

my $dict_tbl;
sub set_dict {
    ($dict_tbl) = @_;
}

sub vyslov {
    if (not defined $dict_tbl) {
        warn 'using vyslov without having set dictionary';
    }
    for (my ($tmp) = @_) {
        my @rv;
        if (/[^\w\s]/) {
            chomp;
            return ["sil"]
        }
        chomp;
        if (my @spec = specialcase()) {
            @rv = @spec;
        }
        init();
        prepis();
        tr/[A-Z]/[a-z]/;
        infreq();
        add_sp();
        push @rv, $_;
        add_variants(\@rv);
        return \@rv;
    }
}

sub specialcase {
    if (not defined $dict_tbl) { return }
    return $dict_tbl->search({ form => $_ })->get_column('pron')->all
}

sub init {
    s/NISM/NYZM/g;
    s/TISM/TYZM/g;
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
    s/^DOUČ/DO!UČ/;
    s/DUKTI/DUKTY/g;
    s/EDIC/EDYC/g;
    s/^EX(?=[AEIOUÁÉÍÓÚŮ])/EGZ/;
    s/ELEKTRONI/ELEKTRONY/g;
    s/ENERGETI/ENERGETY/g;
    s/ETIK/ETYK/g;
    s/EUS/E!US/g;
    s/FEMINI/FEMINY/g;
    s/FINIŠ/FINYŠ/g;
    s/^FREUD/FROJD/g;
    s/MONIE/MONYE/g;
    s/GENETI/GENETY/g;
    s/GIENI/GIENY/g;
    s/IDEU$/IDE!U/;
    s/IMUNI/IMUNY/g;
    s/^INDI(?=.)/INDY/;
    s/INDIV/INDYV/g;
    s/INICI/INYCI/g;
    s/INVESTI/INVESTY/g;
    s/JOSEF/JOZEF/g;
    s/KARATI/KARATY/g;
    s/KARDI/KARDY/g;
    s/KLAUS(?=.)/KLAUZ/g;
    s/KOMUNI/KOMUNY/g;
    s/KONDI/KONDY/g;
    s/KREDIT/KREDYT/g;
    s/KRITI/KRITY/g;
    s/KOMODIT/KOMODYT/g;
    s/KONSOR/KONZOR/g;
    s/LEASING/L ii z ING/g;
    s/LISIEUX/LISIJÉ/;
    s/GITI/GITY/g;
    s/MEDI/MEDY/g;
    s/MOTIV/MOTYV/g;
    s/MANAG/MENEDŽ/g;
    s/NSTI/NSTY/g;
    s/MINI/MINY/g;
    s/MINUS/MÝNUS/g;
    s/ING/YNG/g;
    s/GATIV/GATYV/g;
    s/(?<=.)MATI/MATY/g;
    s/^MATI(?=[^CČN])/MATY/g;
    s/^MATINÉ/MATYNÉ/;
    s/MANIP/MANYP/g;
    s/MODERNI/MODERNY/g;
    s/MUZEU/MUZE!U/;
    s/NAU/NA!U/g;
    s/ZAU/ZA!U/g;
    s/^NE/NE!/;
    s/^ZNE/ZNE!/;
    s/^ODD/OD!D/;
    s/^ODT/OT!T/;
    s/^ODI(?=[^V])/ODY/;
    s/ORGANI/ORGANY/g;
    s/OPTIM/OPTYM/g;
    s/PANICK/PANYCK/g;
    s/PEDIATR/PEDYATR/g;
    s/PERVITI/PERVITY/g;
    s/^PODD/POD!D/g;
    s/^PODT/POT!T/g;
    s/POLITI/POLITY/g;
    s/POZIT/POZYT/g;
    s/^POUČ/PO!UČ/g;
    s/^POULI/PO!ULI/g;
    s/PRIVATI/PRIVATY/g;
    s/PROSTITU/PROSTYTU/g;
    s/^PŘED(?=[^Ě])/PŘED!/;
    s/RADIK/RADYK/g;
    s/^RADIO/RADYO/;
    s/RELATIV/RELATYV/g;
    s/RESTITU/RESTYTU/g;
    s/ROCK/ROK/g;
    s/^ROZ/ROZ!/;
    s/RUTIN/RUTYN/g;
    s/^RÁDI(?=.)/RÁDY/g;
    s/SCHWARZ/ŠVARC/g;
    s/SCHW/ŠV/g;
    s/SHOP/ŠOP/g;
    s/^SEBE/SEBE!/;
    s/^SHO/SCHO/;
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
    s/AUGUSTIN/AUGUSTÝN/g;
    s/^ZAU/ZA!U/g;
    s/ÄH/É/g;
    s/[ÄÆŒ]/É/g;
    y/Å/O/;
    s/[ĆÇ]/C/g;
    s/[ËÈĘ]/E/g;
    y/Ï/Y/;
    s/[ĽĹŁ]/L/g;
    y/Ñ/Ň/;
    s/Ô/UO/g;
    s/ÖH/É/g;
    y/Ö/É/;
    y/Ø/O/;
    y/Ŕ/R/;
    s/ÜH/Ý/g;
    y/Ü/Y/;

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
    s/DŽ/&/g;
    s/DZ/@/g;
    s/X/KS/g;

    # ošetření Ě 
    s/(?<=[BFPV])Ě/JE/g;
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
    s/B(?=[PTŤKSŠCČ#F])/P/g;
    s/B(?=[BDĎGZŽ@&H]$)/P/g;
    s/P(?=[BDĎGZŽ@&H])/B/g;
    s/D$/T/g;
    s/D(?=[PTŤKSŠCČ#F])/T/g;
    s/D(?=[BDĎGZŽ@&H]$)/T/g;
    s/T(?=[BDĎGZŽ@&H])/D/g;
    s/Ď$/Ť/g;
    s/Ď(?=[PTŤKSŠCČ#F])/Ť/g;
    s/Ď(?=[BDĎGZŽ@&H]$)/Ť/g;
    s/Ť(?=[BDĎGZŽ@&H])/Ď/g;
    s/V$/F/g;
    s/V(?=[PTŤKSŠCČ#F])/F/g;
    s/V(?=[BDĎGZŽ@&H]$)/F/g;
    s/F(?=[BDĎGZŽ@&H])/V/g;
    s/G$/K/g;
    s/G(?=[PTŤKSŠCČ#F])/K/g;
    s/G(?=[BDĎGZŽ@&H]$)/K/g;
    s/K(?=[BDĎGZŽ@&H])/G/g;
    s/Z$/S/g;
    s/Z(?=[PTŤKSŠCČ#F])/S/g;
    s/Z(?=[BDĎGZŽ@&H]$)/S/g;
    s/S(?=[BDĎGZŽ@&H])/Z/g;
    s/Ž$/Š/g;
    s/Ž(?=[PTŤKSŠCČ#F])/Š/g;
    s/Ž(?=[BDĎGZŽ@&H]$)/Š/g;
    s/Š(?=[BDĎGZŽ@&H])/Ž/g;
    s/H$/#/g;
    s/H(?=[PTŤKSŠCČ#F])/#/g;
    s/H(?=[BDĎGZŽ@&H]$)/#/g;
    s/#(?=[BDĎGZŽ@&H])/H/g;
    s/\@$/C/g;
    s/\@(?=[PTŤKSŠCČ#F])/C/g;
    s/\@(?=[BDĎGZŽ@&H]$)/C/g;
    s/C(?=[BDĎGZŽ@&H])/\@/g;
    s/&$/Č/g;
    s/&(?=[PTŤKSŠCČ#F])/Č/g;
    s/&(?=[BDĎGZŽ@&H]$)/Č/g;
    s/Č(?=[BDĎGZŽ@&H])/&/g;
    s/Ř$/>/g;
    s/Ř(?=[PTŤKSŠCČ#F])/>/g;
    s/Ř(?=[BDĎGZŽ@&H]$)/>/g;
    s/(?<=[PTŤKSŠCČ#F])Ř/>/g;


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
    s/aw/au/g;
    s/ch/cz/g;
    s/x/ch/g;
    s/dzh/dzs/g;
    s/ew/eu/g;
    s/ow/ou/g;
    s/rsh/rsz/g;
    s/rzh/rzs/g;
    s/sh/sz/g;
    s/dz/ts/g;
    s/zh/zs/g;
}

sub infreq {
    s/dz/c/g;
}

sub add_sp {
    s/ *$/ sp/;
}

sub add_variants {
    my ($rv) = @_;
    if (/^o /) {    # opice => vopice
        push @$rv, "v $_";
    }
    # TODO náct$ => nást, osm(consonant) => osum, ditto sed(u)m, osm => vosm
}

1

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
