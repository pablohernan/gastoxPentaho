var verificaExecucao = function() {
    jconfirm.defaults = {
        columnClass: 'col-lg-4 col-lg-offset-6 col-md-6 col-md-offset-5 col-sm-8 col-sm-offset-4 col-xs-12 col-xs-offset-2',
        theme: 'material',
        icon: 'glyphicon glyphicon-exclamation-sign',
        title: 'ERRO',
        confirmButton: 'OK'
    }
    
    if( !pEmpreendimentoPre ) {
        $.alert({
            content: 'Nenhum empreendimento selecionado!'
        });
        return false;
    }
    
    if( !pInicioPre ) {
        $.alert({
            content: "'Data de' não selecionada!"
        });
        return false;
    }
    else if( !pTerminoPre ) {
        $.alert({
            content: "'Data até' não selecionada!"
        });
        return false;
    }
    else if(!Data.Compara(pInicioPre, pTerminoPre, '-') ) {
        $.alert({
            content: "'Data de' não pode ser maior que 'Data até'!"
        });
        return false;
    }
    
    return true;
}; 