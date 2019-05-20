$(function(){
    Dashboards.setParameter('pInicioPre', Data.formatUS(Data.getPrimeiroMes()));
    Dashboards.setParameter('pTerminoPre', Data.formatUS(Data.Hoje()));
    
    $("#modalFiltros").modal({backdrop: 'static'});
    
    $("body").on('click', '.filtroDiaSemana', function(){
        Dashboards.fireChange('pDiaSemana', '');
        Dashboards.fireChange('pDiaSemanaTxt', '');
        render_diadasemana.update();
    });
    
    $("body").on('click', '.filtroPermanencia', function(){
        Dashboards.fireChange('pPermanencia', '');
        Dashboards.fireChange('pPermanenciaTxt', '');
        render_permanencia.update();
    });
    
    $("body").on('click', '.filtroHora', function(){
        Dashboards.fireChange('pHora', '');
        render_hora.update();
    });
    
    $("body").on('click', '.removeFiltros', function(){
        pDiaSemana = '';
        pDiaSemanaTxt = '';
        pPermanencia = '';
        pPermanenciaTxt = '';
        pHora = '';
        $("#modalFiltros").modal('hide');
        Dashboards.fireChange('init', init);
    });
}); 