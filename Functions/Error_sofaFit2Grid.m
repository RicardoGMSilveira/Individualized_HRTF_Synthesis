clear all; clc
% Avalia��o de performance entre modelos de interpola��o de posi��es de HRTFs
% Davi R. Carvalho - Abril/2020
addpath(genpath('B:\Documentos\MATLAB\SUpDEq-master'))

%% LOAD 
local = 'B:\Documentos\#3 - TCC\EAC-TCC-Davi\HRTF-datasets\';    
pathari = dir([local 'Banco ARI\HRTF_DTF\database\ari\hrtf b_nh*.sofa']);
% pathari = dir([local 'Banco CIPIC\SOFA\*.sofa']);
for l = 1:length(pathari)
   dataset(l).dados = SOFAload([pathari(l).folder, '\',pathari(l).name], 'nochecks');
end
% dataset([1:10]) = [];
fs = dataset(1).dados.Data.SamplingRate;
fmin=100; fmax=19000; 
n=0;
for no_readpt = 50:100:650 % n�mero de posi��es "objetivo" (removidas pro teste)
%     no_readpt = 250
    n=n+1;
    disp(['Itera��o: ' num2str(n) ' de 7' ])
    %% Selecionar posi��es a serem removidas
    no_posi = size(dataset(1).dados.SourcePosition,1)-10; % numero total de posi��es
    idx = randperm(no_posi, no_readpt); % indice de posi��es (pseudo)aleatorias

    %% Create new SOFA objects
    for ks = 1:length(dataset)  % numero de individuos sob analise 
        clear REAL Obj_stdy
        % HRIRs
        src_IR   = dataset(ks).dados.Data.IR;
        des_IR   = src_IR(idx,:,:); % RI objetivo
        inpt_IR  = src_IR;          
        inpt_IR(idx,:,:) = [];      % RI de entrada

        % Posi��es  
        inpt_pos = dataset(ks).dados.SourcePosition;
        des_pos  = inpt_pos(idx,:); % Posicoes objetivo
        inpt_pos(idx,:)  = [];      % Posicoes de entrada    
        %save para plot
        plt(n).des  = des_pos;
        plt(n).inpt = inpt_pos;

        % SOFA sem posi��es objetivo (ENTRADA)
        Obj_stdy = SOFAgetConventions('SimpleFreeFieldHRIR');
        Obj_stdy.Data.IR = inpt_IR;
        Obj_stdy.Data.SamplingRate = fs;
        Obj_stdy.SourcePosition = inpt_pos;

        % SOFA com posi��es objetivo (OBJETIVO)
        REAL = SOFAgetConventions('SimpleFreeFieldHRIR');
        REAL.Data.IR = des_IR;
        REAL.Data.SamplingRate = fs;
        REAL.SourcePosition = des_pos;
        % update metadata
        REAL = SOFAupgradeConventions( SOFAupdateDimensions(REAL));    
        Obj_stdy = SOFAupgradeConventions( SOFAupdateDimensions(Obj_stdy));   

    %% Estimar posicoes objetivo a partir das posicoes de entrada
        ADPT = sofaFit2Grid(Obj_stdy, des_pos, 'adapt'); 
        HYBR = sofaFit2Grid(Obj_stdy, des_pos, 'hybrid');
        VBAP = sofaFit2Grid(Obj_stdy, des_pos, 'vbap');
        BLIN = sofaFit2Grid(Obj_stdy, des_pos, 'bilinear');
        
    %% Erro espectral
        sd(n).adpt(:,ks) = sofaSpecDist(ADPT, REAL, fmin,fmax);
        sd(n).vbap(:,ks) = sofaSpecDist(VBAP, REAL, fmin,fmax);
        sd(n).blin(:,ks) = sofaSpecDist(BLIN, REAL, fmin,fmax);
        sd(n).hybr(:,ks) = sofaSpecDist(HYBR, REAL, fmin,fmax);

    %% ERRO ITD e ILD 
        [ITD_error(n).adpt(:,ks), ILD_error(n).adpt(:,ks)] = sofa_ITD_ILD_error(ADPT, REAL);
        [ITD_error(n).hybr(:,ks), ILD_error(n).hybr(:,ks)] = sofa_ITD_ILD_error(HYBR, REAL);
        [ITD_error(n).vbap(:,ks), ILD_error(n).vbap(:,ks)] = sofa_ITD_ILD_error(VBAP, REAL);
        [ITD_error(n).blin(:,ks), ILD_error(n).blin(:,ks)] = sofa_ITD_ILD_error(BLIN, REAL);        
    end
end







%%
% save('workspace_Error_sofaFit2Grid.mat')
% clear all
load('workspace_Error_sofaFit2Grid.mat')







%%%%%%%%%%%%%% PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simplica��o do erro para compara��o (ITD, ILD)
% for k = 1:n
%     media_itd(k).adpt = mean(mean([ITD_error(k).adpt], 2));
%     media_itd(k).vbap = mean(mean([ITD_error(k).vbap], 2));
%     media_itd(k).blin = mean(nanmean([ITD_error(k).blin], 2));
%     media_itd(k).hybr = mean(mean([ITD_error(k).hybr], 2));
%     std_itd(k).adpt = std(mean([ITD_error(k).adpt], 2));
%     std_itd(k).vbap = std(mean([ITD_error(k).vbap], 2));
%     std_itd(k).blin = std(nanmean([ITD_error(k).blin], 2));
%     std_itd(k).hybr = std(mean([ITD_error(k).hybr], 2));
% 
%     
%     media_ild(k).adpt = mean(mean([ILD_error(k).adpt], 2));
%     media_ild(k).vbap = mean(mean([ILD_error(k).vbap], 2));
%     media_ild(k).blin = mean(nanmean([ILD_error(k).blin], 2));
%     media_ild(k).hybr = mean(mean([ILD_error(k).hybr], 2));
%     std_ild(k).adpt = std(mean([ILD_error(k).adpt], 2));
%     std_ild(k).vbap = std(mean([ILD_error(k).vbap], 2));
%     std_ild(k).blin = std(nanmean([ILD_error(k).blin], 2));
%     std_ild(k).hybr = std(mean([ILD_error(k).hybr], 2));
% 
% end

% plot([media_itd.adpt], 'linewidth', 1.7);hold on
% plot([media_itd.vbap], 'linewidth', 1.7);
% plot([media_itd.blin], 'linewidth', 1.7);
% plot([media_itd.hybr], 'linewidth', 1.7);
% xticks(1:n);
% legend('adapt', 'vbap', 'blin', 'hybr', 'location', 'best')
% 
% 
% figure()
% plot([media_ild.adpt], 'linewidth', 1.7);hold on
% plot([media_ild.vbap], 'linewidth', 1.7);
% plot([media_ild.blin], 'linewidth', 1.7);
% plot([media_ild.hybr], 'linewidth', 1.7);
% xticks(1:n);
% legend('adapt', 'vbap', 'blin', 'hybr', 'location', 'best')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simplica��o do erro para compara��o (LSD)
for l = 1:n
    % m�dia do erro de todas as posi��es para cada individuo
    pos_sd(l).adpt = nanmean(sd(l).adpt);
    pos_sd(l).hybr = nanmean(sd(l).hybr);
    pos_sd(l).vbap = nanmean(sd(l).vbap);
    pos_sd(l).blin = nanmean(sd(l).blin);

    % m�dia de todas as posi��es e todos os individuos
    media_sd(l).adpt = mean(pos_sd(l).adpt);
    stdev(l).adpt    = std(pos_sd(l).adpt); %std entre media de cada indiv�duo

    media_sd(l).hybr = mean(pos_sd(l).hybr);
    stdev(l).hybr    = std(pos_sd(l).hybr);

    media_sd(l).vbap = mean(pos_sd(l).vbap);
    stdev(l).vbap    = std(pos_sd(l).vbap);

    media_sd(l).blin = mean(pos_sd(l).blin);
    stdev(l).blin    = std(pos_sd(l).blin);
end

%% Media do erro para todas as posi��es e todos os individuos com desvio
% padrao entre individuos 
hFigure = figure();
set(0,'DefaultLineLineWidth',1.5)

fig1 = shadedErrorBar(1:n, [media_sd.adpt], [stdev.adpt],{'Color',colors(0),'LineWidth', 1.7},1,0.2,'lin', 0);hold on
fig2 = shadedErrorBar(1:n, [media_sd.vbap], [stdev.vbap],{'Color',colors(1),'LineWidth', 1.7},1,0.2,'lin', 0);
fig3 = shadedErrorBar(1:n, [media_sd.blin], [stdev.blin],{'Color',colors(2),'LineWidth', 1.7},1,0.2,'lin', 0);
fig4 = shadedErrorBar(1:n, [media_sd.hybr], [stdev.hybr],{'Color',colors(7),'LineWidth', 1.7},1,0.2,'lin', 0);hold off

%metadata
axis tight
h = get(gca,'Children');
legendstr = {'', 'Adapta��o', '', 'VBAP', '', 'Bilinear', '', 'H�brido'};
legend(h([1 3 5 7]), legendstr{[8 6 4 2]}, 'Location', 'Best')
xticks(1:n)
xticklabels(50:100:750)
title('')
xlabel('N�mero de posi��es estimadas')
ylabel('Erro espectral [dB]')
set(gca,'FontSize',12)

filename = [pwd, '\Images\ShadedError_sofaFit2Grid.pdf'];
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')

%% Mapa de ERRO por posi��o 
lim_colorbar = [1 8];
n_idx = 4; % 
plt_pos = plt(n_idx).des;
plt_inp =  plt(n_idx).inpt;

% ADPT
hFigure = figure();
scatter(plt_pos(:,1), plt_pos(:,2), 35, nanmean(sd(n_idx).adpt,2), 'filled'); 
title('Distor��o espectral - (Adapta��o)')
xlabel('Azimute [�]')
ylabel('Eleva��o [�]')
axis tight
c = colorbar; caxis(lim_colorbar); colormap jet
c.Label.String = 'Distor��o Espectral [dB]';
set(gca,'FontSize',12)
set(gca,'Color','k');
filename = [pwd, '\Images\MAP_ADAPT_sofaFit2Grid.pdf'];
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')
 
%close  VBAP
hFigure = figure();
scatter(plt_pos(:,1), plt_pos(:,2), 35, nanmean(sd(n_idx).vbap,2), 'filled');
title('Distor��o espectral logaritmica - (VBAP)')
xlabel('Azimute [�]')
ylabel('Eleva��o [�]')
axis tight
c = colorbar; caxis(lim_colorbar); colormap jet
c.Label.String = 'Distor��o Espectral [dB]';
set(gca,'FontSize',12)
set(gca,'Color','k')
filename = [pwd, '\Images\MAP_VBAP_sofaFit2Grid.pdf'];
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')
 
% BILINEAR
hFigure = figure();
scatter(plt_pos(:,1), plt_pos(:,2), 35, nanmean(sd(n_idx).blin,2), 'filled');
title('Distor��o espectral logaritmica - (Bilinear)')
xlabel('Azimute [�]')
ylabel('Eleva��o [�]')
axis tight
c = colorbar; caxis(lim_colorbar); colormap jet
c.Label.String = 'Distor��o Espectral [dB]';
set(gca,'FontSize',12)
set(gca,'Color','k')
filename = [pwd, '\Images\MAP_BILIN_sofaFit2Grid.pdf'];
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')


%% Visualiaza��o de posi��es input e target
hFigure = figure();
scatter(plt(4).inpt(:,1), plt(4).inpt(:,2), 28, 'filled',  'black')
hold on 
scatter(plt(4).des(:,1), plt(4).des(:,2), 28, 'filled', 'red')
title('Posi��es objetivo dentro do grid original')
xlabel('Azimute [�]')
ylabel('Eleva��o [�]')
axis tight
set(gca,'FontSize',12) 


legend('Posi��es de entrada',  'Posi��es objetivo', 'Location', 'best' )
filename = [pwd, '\Images\removedPos_sofaFit2Grid.pdf'];
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')



%% Probabilidade distribui��o 
n_idx = 4; % 
hFigure = figure();
histogram(mean(sd(n_idx).adpt,2),'Normalization','probability', 'NumBins', 13)
ylim([0 .35])
ytix = get(gca, 'YTick');
set(gca, 'YTick',ytix, 'YTickLabel',ytix*100);

xlabel('Distor��o espectral [dB]')
ylabel('Probabilidade [%]')
title('Distribui��o da distor��o espectral (Adapta��o)')
xlim([0 22.5])
xticks(0:2:100)
set(gca,'FontSize',12)
filename = [pwd, '\Images\Prob_fit2grid_ADPT.pdf'];
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')



% VBAP
hFigure = figure();
histogram(mean(sd(n_idx).vbap,2),'Normalization','probability', 'NumBins', 13)
ylim([0 .35])
ytix = get(gca, 'YTick');
set(gca, 'YTick',ytix, 'YTickLabel',ytix*100);

xlabel('Distor��o espectral [dB]')
ylabel('Probabilidade [%]')
title('Distribui��o da distor��o espectral (VBAP)')
xlim([0 22.5])
xticks(0:2:100)
set(gca,'FontSize',12)
filename = [pwd, '\Images\Prob_fit2grid_VBAP.pdf'];
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')



% BILINEAR
hFigure = figure();
histogram(mean(sd(n_idx).blin,2),'Normalization','probability', 'NumBins', 13)
ylim([0 .35])
ytix = get(gca, 'YTick');
set(gca, 'YTick',ytix, 'YTickLabel',ytix*100);

xlabel('Distor��o espectral [dB]')
ylabel('Probabilidade [%]')
title('Distribui��o da distor��o espectral (Bilinear)')
xlim([0 22.5])
xticks(0:2:100)
set(gca,'FontSize',12)
filename = [pwd, '\Images\Prob_fit2grid_BLIN.pdf'];
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')

