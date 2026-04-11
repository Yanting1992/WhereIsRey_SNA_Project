# =====================================================
# #WhereIsRey 语义网络分析
# 基于 Miranda (Social Analytics) Chapter 11
# =====================================================

# 1. 加载包 ----------------------------------------------------------
library(tm)
library(igraph)
library(wordcloud)
library(RColorBrewer)

# 2. 读取数据 --------------------------------------------------------
ReyPosts <- read.csv('WheresRey.csv', header = TRUE, stringsAsFactors = FALSE)

# 3. 编码清理（解决中文系统问题）----------------------------------------
ReyPosts$Posts <- iconv(ReyPosts$Posts, from = 'UTF-8', to = 'ASCII', sub = ' ')

# 4. 创建语料库并预处理 ------------------------------------------------
ReyCorp <- Corpus(VectorSource(ReyPosts$Posts))

# 定义清理函数
StripString <- content_transformer(function(x, pattern) gsub(pattern, '', x))
SearchReplace <- content_transformer(function(x, pattern1, pattern2) gsub(pattern1, pattern2, x))
latin2ascii = content_transformer(function(x) iconv(x, 'latin1', 'ascii', sub = ''))

# 执行预处理
ReyCorp = tm_map(ReyCorp, latin2ascii) 
ReyCorp = tm_map(ReyCorp, content_transformer(tolower))
ReyCorp = tm_map(ReyCorp, removePunctuation)
ReyCorp = tm_map(ReyCorp, removeNumbers)
ReyCorp = tm_map(ReyCorp, stripWhitespace)
ReyCorp = tm_map(ReyCorp, StripString, 'http://[[a1num*]]/')
ReyCorp = tm_map(ReyCorp, StripString, '[\r\n]')
ReyCorp = tm_map(ReyCorp, StripString, '[\t]')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'theforceawakens', 'the force awakens')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'merchsexismproblem', 'merch sexism problem')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'highlightsdearthfemaletoyhtml', 'highlights dearth female toy')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'forceawakens', 'force awakens')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'awakens', 'awake')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'awaken', 'awake')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'arewereallygoingtostart', 'are we really going to start')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'makers', 'maker')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'highlights', 'highlight')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'figures', 'figure')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'merchandise', 'merch')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'merchs', 'merch')
ReyCorp = tm_map(ReyCorp, SearchReplace, 'shes', 'she is')
ReyCorp = tm_map(ReyCorp, StripString, 'http*')
ReyCorp = tm_map(ReyCorp, StripString, 'www*')
ReyCorp = tm_map(ReyCorp, StripString, '*html*')
ReyCorp = tm_map(ReyCorp, StripString, '*com*')
ReyCorp = tm_map(ReyCorp, removeWords, stopwords('english'))

# 5. 创建词项-文档矩阵并移除稀疏词 ----------------------------------------
ReyTDM <- TermDocumentMatrix(ReyCorp)
ReyTDM <- removeSparseTerms(ReyTDM, 0.95)

# 6. 语义网络分析（两层关联）-------------------------------------------
term <- 'whereisrey'

# 第一层
Reynet1 <- as.data.frame(findAssocs(ReyTDM, term, 0.10))
Reynet1 <- cbind(term, row.names(Reynet1), Reynet1)
colnames(Reynet1) <- c('word1', 'word2', 'freq')
rownames(Reynet1) <- NULL

# 第二层（循环扩展）
Reynet2 <- Reynet1
for (i in 1:nrow(Reynet1))
  {term = Reynet1$word2[i]
  Reynetterm = as.data.frame(findAssocs(ReyTDM, term, 0.10))
  Reynetterm = cbind(term, rownames(Reynetterm), Reynetterm)
  colnames(Reynetterm) = c('word1', 'word2', 'freq')
  rownames(Reynetterm) = NULL
  Reynet2 = as.data.frame(rbind(Reynet2, Reynetterm))}

# 7. 绘制并保存语义网络图 ---------------------------------------------
g <- graph_from_data_frame(Reynet2, directed = FALSE)
g <- simplify(g, remove.multiple = TRUE, remove.loops = TRUE)

png('semantic_network.png', width = 1000, height = 800)
plot(g, 
     vertex.size = degree(g) * 1.5,
     vertex.label.cex = 0.8,
     vertex.label.color = 'black',
     vertex.color = 'skyblue',
     edge.color = 'gray50',
     main = 'Semantic Network around #WhereIsRey')
dev.off()

# 8. 层次聚类与树状图 ------------------------------------------------
ReyDist = dist(ReyTDM, method = 'euclidean')
ReyHClust = hclust(d=ReyDist, method = 'ward.D')
plot(ReyHClust)

png('dendrogram.png', width = 1000, height = 600)
plot(ReyHClust, main = 'Hierarchical Clustering of Keywords')
rect.hclust(ReyHClust, k = 4, border = 2:5)
dev.off()

# 9. 完成 ----------------------------------------------------------
print("分析完成！图表已保存到当前文件夹")