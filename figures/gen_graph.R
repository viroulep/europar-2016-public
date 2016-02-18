library(ggplot2)
library(plyr)

datafile = commandArgs(TRUE)[1]
wholeframe = read.table(datafile, header=TRUE)

pd = position_dodge(width=.1)



#Graph for distribution

framedistrib = subset(wholeframe, WSpush_init!="numactl" & WSpush_init != "defaultnuma" & Runtime == "komp" & WSpush_init != "none" & WSselect != "hws_P_N" & WSselect != "hws_N" & WSpush != "Wnuma" & Strict_Push == "loose" & Progname == "dpotrf_taskdep" & (Size=="32768" & Blocksize == "512"))
framebasegcc = subset(wholeframe, WSpush_init=="none" & Runtime == "gomp" & WSselect == "none" & WSpush == "none" & Strict_Push == "loose" & Progname == "dpotrf_taskdep" & (Size=="32768" & Blocksize == "512"))
framebasegcc_para = subset(wholeframe, WSpush_init=="parallel_init" & Runtime == "gomp" & WSselect == "none" & WSpush == "none" & Strict_Push == "loose" & Progname == "dpotrf_taskdep" & (Size=="32768" & Blocksize == "512"))
framenumactl_gcc = subset(wholeframe, WSpush_init=="numactl" & Runtime == "gomp" & WSselect == "none" & WSpush == "none" & Strict_Push == "loose" & Progname == "dpotrf_taskdep" & (Size=="32768" & Blocksize == "512"))
framsum = ddply(framedistrib, c("Runtime","WSselect", "Progname", "WSpush","WSpush_init", "Strict_Push", "Size","Blocksize","Threads"), summarize, GFlops = mean(Gflops), Std = sd(Gflops), Nxp=length(Runtime))
framsumbasegcc = ddply(framebasegcc, c("Runtime","WSselect", "Progname", "WSpush","WSpush_init", "Strict_Push", "Size","Blocksize","Threads"), summarize, GFlops = mean(Gflops), Std = sd(Gflops), Nxp=length(Runtime))
framsumbasegcc_para = ddply(framebasegcc_para, c("Runtime","WSselect", "Progname", "WSpush","WSpush_init", "Strict_Push", "Size","Blocksize","Threads"), summarize, GFlops = mean(Gflops), Std = sd(Gflops), Nxp=length(Runtime))
framsumnumactl_gcc = ddply(framenumactl_gcc, c("Runtime","WSselect", "Progname", "WSpush","WSpush_init", "Strict_Push", "Size","Blocksize","Threads"), summarize, GFlops = mean(Gflops), Std = sd(Gflops), Nxp=length(Runtime))
pdf("graph_distrib.pdf", width = 10, height=4)


myplot = ggplot(framsum, aes(x=factor(WSpush_init), y = GFlops, fill=interaction(Strict_Push, WSselect, WSpush)))
myplot = myplot + geom_bar(stat="identity", position=position_dodge())
myplot = myplot + geom_errorbar(show.legend=FALSE, position=position_dodge(0.9), aes(color=interaction(Strict_Push, WSselect, WSpush), ymin=GFlops-(2*Std/Nxp), ymax=GFlops+(2*Std/Nxp), width=.1))
myplot = myplot + facet_wrap(Size~Blocksize, ncol=4)
myplot = myplot + theme(legend.position="right", legend.title=element_text(size=14), legend.text=element_text(size=13), axis.text=element_text(size=12))
myplot = myplot + ggtitle("Cholesky's performances using 32K matrices depending on the data distribution\n")
myplot = myplot + scale_fill_grey(name="", labels=c("sRand\npLoc", "sRandNuma\npLocNum", "sNumaProc\npNumaWLoc", "sProc\npNumaWLoc"))
myplot = myplot + scale_x_discrete(name="Data distribution")
myplot = myplot + geom_hline(aes(yintercept=framsumnumactl_gcc$GFlops), linetype="dashed")
myplot = myplot + geom_text(aes(3.2, framsumnumactl_gcc$GFlops, label="GCC init-seq\n+ Numactl"), vjust=0.5, hjust=1.05, size=4.5, family="Courier")
myplot = myplot + geom_hline(aes(yintercept=framsumbasegcc_para$GFlops))
myplot = myplot + geom_text(aes(3.2, framsumbasegcc_para$GFlops, label="GCC init-para"), vjust=-0.6, hjust=1.05, size=4.5, family="Courier")
myplot = myplot + geom_hline(aes(yintercept=framsumbasegcc$GFlops), linetype="twodash")
myplot = myplot + geom_text(aes(3.2, framsumbasegcc$GFlops, label="GCC init-seq"), vjust=1.5, hjust=1.05, size=4.5, family="Courier")
myplot = myplot + scale_color_grey()
myplot = myplot + guides(fill=guide_legend(nrow=4, byrow=TRUE, keyheight=3), color=FALSE)


print(myplot)
dev.off()

#Generate the "Strict" graph, we'd better just make an explanation about it

#framestrict = subset(wholeframe, Progname == "dpotrf_taskdep" & WSpush_init != "defaultnuma" & WSpush_init != "numactl" & ((Size=="16384" & Blocksize == "256") | (Size=="32768" & Blocksize == "512")) & ((WSselect == "hws_N_P" & WSpush == "Whws") | (WSselect == "hws_N" & WSpush == "Whws")))
#framsum = ddply(framestrict, c("Runtime","WSselect", "Progname", "WSpush","WSpush_init", "Strict_Push", "Size","Blocksize","Threads"), summarize, GFlops = mean(Gflops), Std = sd(Gflops), Nxp=length(Runtime))
#pdf("graph_strict.pdf", width = 10, height=6)


#myplot = ggplot(framsum, aes(x=factor(WSpush_init), y = GFlops, fill=interaction(Strict_Push, WSselect, WSpush)))
#myplot = myplot + geom_bar(stat="identity", position=position_dodge())
#myplot = myplot + geom_errorbar(position=position_dodge(0.9), aes(color=interaction(Strict_Push, WSselect, WSpush), ymin=GFlops-(2*Std/Nxp), ymax=GFlops+(2*Std/Nxp), width=.1))
#myplot = myplot + facet_wrap(Size~Blocksize, ncol=4)
#myplot = myplot + theme(legend.position="bottom")
#myplot = myplot + scale_fill_discrete(name="Strategy (WSselect + WSpush) : ", labels=c("Loose (sNuma + pNumaWLoc)", "Strict (sNuma + pNumaWLoc)", "Loose (sNumaProc + pNumaWLoc)", "Strict (sNumaProc + pNumaWLoc)"))
#myplot = myplot + scale_x_discrete(name="Data distribution")
#myplot = myplot + guides(fill=guide_legend(nrow=2, byrow=TRUE), color=FALSE)
#myplot = myplot + ggtitle("Cholesky's performances using 16K and 32K matrices for strict or loose strategy\n")


#print(myplot)
#dev.off()



frame_eval_strat = subset(wholeframe, (Progname == "dpotrf_taskdep" & Size=="32768" & Blocksize == "512" & Strict_Push == "loose") & (WSpush_init == "cyclicnuma"))
frame_baseline = subset(wholeframe, (Progname == "dpotrf_taskdep" & Size=="32768" & Blocksize == "512" & Strict_Push == "loose") & (Runtime == "gomp" & WSpush_init == "parallel_init"))
framsum = ddply(frame_eval_strat, c("Runtime","WSselect", "Progname", "WSpush","WSpush_init", "Strict_Push", "Size","Blocksize","Threads"), summarize, GFlops = mean(Gflops), Std = sd(Gflops), Nxp=length(Runtime))
framsumbaseline = ddply(frame_baseline, c("Runtime","WSselect", "Progname", "WSpush","WSpush_init", "Strict_Push", "Size","Blocksize","Threads"), summarize, GFlops = mean(Gflops), Std = sd(Gflops), Nxp=length(Runtime))
pdf("graph_all_strat.pdf", width = 10, height=4)


myplot = ggplot(framsum, aes(x=factor(Progname), y = GFlops, fill=interaction(Runtime, Strict_Push, WSselect, WSpush)))
myplot = myplot + geom_bar(stat="identity", position=position_dodge())
myplot = myplot + geom_errorbar(position=position_dodge(0.9), aes(color=interaction(Runtime, Strict_Push, WSselect, WSpush), ymin=GFlops-(2*Std/Nxp), ymax=GFlops+(2*Std/Nxp), width=.1))
myplot = myplot + facet_wrap(Size~Blocksize, ncol=4)
myplot = myplot + theme(legend.position="right", legend.title=element_text(size=14), legend.text=element_text(size=13), axis.text=element_text(size=12))
myplot = myplot + scale_x_discrete(name="", breaks=NULL)
myplot = myplot + ylim(0, 2500)
myplot = myplot + guides(fill=guide_legend(nrow=4, byrow=TRUE, keyheight=2.3), color=FALSE)
myplot = myplot + scale_fill_grey(name="", labels=c("1: sRand\n    pLoc", "2: sRandNuma\n    pLocNum", "3: sNuma\n    pNumaWLoc", "4: sNumaProc\n    pNumaWLoc", "5: sProc\n    pNumaWLoc", "6: sProcNuma\n    pNumaWLoc", "7: sRandNuma\n    pNumaW"))
myplot = myplot + geom_hline(aes(yintercept=framsumbaseline$GFlops), linetype="dashed")
myplot = myplot + geom_text(aes(1.4, framsumbaseline$GFlops, label="GCC"), vjust=1.5, hjust=-0.5, size=5, family="Courier")
myplot = myplot + scale_color_grey()
myplot = myplot + ggtitle("Cholesky's performances using 32K matrices depending on the strategy\n")



print(myplot)
dev.off()


frame_eval_detail_strat = subset(wholeframe, Runtime == "komp" & ((Blocksize == "512" & Size != "16384") | (Blocksize == "256" & Size == "16384")) & WSpush_init == "cyclicnuma" & Strict_Push == "loose" & ((WSselect == "rand" & WSpush == "local") | (WSselect == "hws_N_P" & WSpush == "Whws") | (WSselect == "numa" & WSpush == "Wnuma")))

 #& ((Size=="16384" & Blocksize == "256") | (Size=="32768" & Blocksize == "512")))
framsum = ddply(frame_eval_detail_strat, c("Runtime","WSselect", "Progname", "WSpush","WSpush_init", "Strict_Push", "Size","Blocksize","Threads"), summarize, GFlops = mean(Gflops), Std = sd(Gflops), Nxp=length(Runtime))
pdf("graph_details_strat.pdf", width = 10, height=4)

levels(framsum$Progname) <- c("QR", "Cholesky")

myplot = ggplot(framsum, aes(x=factor(Size), y = GFlops, fill=interaction(Strict_Push, WSselect, WSpush)))
myplot = myplot + geom_bar(stat="identity", position=position_dodge())
myplot = myplot + geom_errorbar(position=position_dodge(0.9), aes(color=interaction(Strict_Push, WSselect, WSpush), ymin=GFlops-(2*Std/Nxp), ymax=GFlops+(2*Std/Nxp), width=.1))
myplot = myplot + facet_grid(~Progname)
myplot = myplot + theme(legend.position="right", legend.title=element_text(size=14), legend.text=element_text(size=13), axis.text=element_text(size=12))
myplot = myplot + scale_x_discrete(name="Matrix size (best BS)")
myplot = myplot + scale_color_grey()
myplot = myplot + ggtitle("Cholesky and QR performances for multiple sizes\n")
myplot = myplot + scale_fill_grey(name="", labels=c("sRand\npLoc", "sNumaProc\npNumaWLoc", "sRandNuma\npNumaW"))
myplot = myplot + guides(fill=guide_legend(nrow=3, byrow=TRUE, keyheight=3), color=FALSE)



print(myplot)
dev.off()


