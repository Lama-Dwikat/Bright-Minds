import axios from "axios";

export const imageSearchService = {
  async searchImages(query, perPage = 20) {
    const response = await axios.get("https://pixabay.com/api/", {
      params: {
        key: process.env.PIXABAY_API_KEY,
        q: query,
        image_type: "illustration",
        safesearch: true,
        per_page: perPage,
      },
    });

    return response.data.hits.map((img) => ({
      id: img.id,
      previewURL: img.previewURL,
      largeImageURL: img.largeImageURL,
      tags: img.tags,
    }));
  },
};
