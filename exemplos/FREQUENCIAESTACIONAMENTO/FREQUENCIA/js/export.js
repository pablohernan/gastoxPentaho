function formatar(nome, dados) {
    var metadados = dados.metadata;
    var resultado = dados.resultset;
    var i, linha;
    
    if(nome == 'Clientes / dia') {
        metadados[0].colName = metadados[0].colName.toUpperCase();
        metadados[0].colType = 'String';
        metadados[1].colName = metadados[1].colName.toUpperCase();
        metadados[1].colType = 'Integer';
        
        for(i = 0; i < resultado.length; i ++) {
            linha = resultado[i];
            linha[0] = linha[0] ? Data.fixformat(linha[0]) : '';
            linha[1] = linha[1] ? linha[1] : 0;
        }
    }
    else if(nome == 'Frequência / dia da semana') {
        metadados.shift();
        metadados.pop();
        metadados[0].colType = 'String';
        metadados[0].colName = metadados[0].colName.toUpperCase();
        metadados[1].colType = 'Integer';
        metadados[1].colName = metadados[1].colName.toUpperCase();
        metadados[2].colType = 'Numeric';
        metadados[2].colName = metadados[2].colName.toUpperCase();
        metadados[3].colType = 'Numeric';
        metadados[3].colName = metadados[3].colName.toUpperCase();
        
        for(i = 0; i < resultado.length; i ++) {
            linha = resultado[i];
            linha.shift();
            linha.pop();
            linha[0] = linha[0] ? linha[0].toUpperCase() : linha[0];
            linha[1] = linha[1] ? linha[1] : 0;
            linha[2] = linha[2] ? linha[2] : 0;
            linha[3] = linha[3] ? linha[3] : 0;
        }
    }
    else if(nome == 'Frequência / tempo de permanência') {
        metadados[0].colType = 'String';
        metadados[0].colName = metadados[0].colName.toUpperCase();
        metadados[1].colType = 'Integer';
        metadados[1].colName = metadados[1].colName.toUpperCase();
        
        for(i = 0; i < resultado.length; i ++) {
            linha = resultado[i];
            switch(linha[0]) {
                case 'ATE_1H':
                    linha[0] =  'Até 1h';
                break;
                case '1H_2H':
                    linha[0] = '1h a 2h';
                break;
                case '2H_3H':
                    linha[0] = '2h a 3h';
                break;
                case '3H_4H':
                    linha[0] = '3h a 4h';
                break;
                case 'ACIMA_4H':
                    linha[0] = 'Acima de 4h';
                break;
            }
            linha[1] = linha[1] ? linha[1] : 0;
        }
    }
    else if(nome == 'Frequências / clientes') {
        metadados.shift();
        metadados.pop();
        metadados[0].colType = 'String';
        metadados[0].colName = metadados[0].colName.toUpperCase();
        metadados[1].colType = 'Integer';
        metadados[1].colName = metadados[1].colName.toUpperCase();
        
        for(i = 0; i < resultado.length; i ++) {
            linha = resultado[i];
            linha.shift();
            linha.pop();
            linha[0] = linha[0] ? linha[0] : '';
            linha[1] = linha[1] ? linha[1] : 0;
        }
    }
    else if(nome == 'Frequência / horário') {
        var novoResultado = [];
        var horaMin = parseInt(pHoraMin, 10);
        var horaMax = parseInt(pHoraMax, 10);
        
        metadados[0].colType = 'String';
        metadados[0].colName = metadados[0].colName.toUpperCase();
        
        if (pHorarioOpcao === '1') {
            metadados.splice(1, 1);
            metadados[1].colType = 'Numeric';
        } else {
            metadados.splice(2, 1);
            metadados[1].colType = 'Integer';
        }
        
        metadados[1].colName = metadados[1].colName.toUpperCase();
        
        for(i = 0; i < resultado.length; i ++) {
            linha = resultado[i];
        
            if (pHorarioOpcao === '1') {
                linha.splice(1, 1);
            } else {
                linha.splice(2, 1);
            }
            
            linha[0] = linha[0] ? linha[0] : '';
            linha[1] = linha[1] ? linha[1] : 0;
            
            var hora = parseInt(linha[0], 10);
    
            if(hora >= horaMin && hora <= horaMax) {
                novoResultado.push(linha);
            }
        }
        dados.resultset = novoResultado;
    }
    else if(nome == 'Top clientes') {
        metadados.splice(0, 2);
        metadados[0].colName = metadados[0].colName.toUpperCase();
        metadados[0].colType = 'String';
        metadados[1].colName = metadados[1].colName.toUpperCase();
        metadados[1].colType = 'String';
        metadados[2].colName = metadados[2].colName.toUpperCase();
        metadados[2].colType = 'String';
        metadados[3].colName = metadados[3].colName.toUpperCase();
        metadados[3].colType = 'Integer';
        metadados[4].colName = metadados[4].colName.toUpperCase();
        metadados[4].colType = 'String';
        metadados[5].colName = metadados[5].colName.toUpperCase();
        metadados[5].colType = 'String';
        metadados[6].colName = metadados[6].colName.toUpperCase();
        metadados[6].colType = 'String';
        
        for(i = 0; i < resultado.length; i ++) {
            linha = resultado[i];
            linha.splice(0, 2);
            linha[0] = linha[0] ? linha[0].toUpperCase() : linha[0];
            linha[1] = linha[1] ? linha[1] : '';
            linha[2] = linha[2] ? linha[2] : '';
            linha[3] = linha[3] ? linha[3] : 0;
            linha[4] = linha[4] ? Data.formatDtHr(linha[4]) : '';
            linha[5] = linha[5] ? linha[5] : '';
            linha[6] = linha[6] ? linha[6] : '';
        }
    }
}